#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <glib.h>
#include <dirent.h>
#include <gnutls/gnutls.h>
#include <gnutls/crypto.h>
#include <attr/xattr.h>

struct digest_t {
        char *name;
        gnutls_digest_algorithm_t type;
};

gnutls_digest_algorithm_t dig_alg = GNUTLS_DIG_UNKNOWN;

struct digest_t digest_types[] = {
        {"MD5", GNUTLS_DIG_MD5},
        {"SHA1", GNUTLS_DIG_SHA1},
        {"RMD160", GNUTLS_DIG_RMD160},
        {"MD2", GNUTLS_DIG_MD2},
        {"SHA256", GNUTLS_DIG_SHA256},
        {"SHA384", GNUTLS_DIG_SHA384},
        {"SHA512", GNUTLS_DIG_SHA512},
        {"SHA224", GNUTLS_DIG_SHA224},
        {NULL, 0}
};

int set_opt=0;
int verify_opt=0;
int follow_links_opt=0;

int initqdepth=0;

void walk_down_dir(char *directory, GQueue *worknames);
int is_dir(char *name);
int walk_dir(GQueue *worknames, int recursive);
int process_file(char *name);
void walk_down_dir(char *directory, GQueue *worknames);

char attr_name[100];

int
main(int argc, char *argv[]) 
{
        GQueue *worknames=g_queue_new();
        char recursive=0;
        int opt;
        char *dig="SHA512";
        int i;
        gnutls_hash_hd_t digest;

        while((opt = getopt(argc, argv, "rd:svlh")) != -1) {
                switch(opt) {
                        case 'r':
                                recursive = 1;
                                break;
                        case 'd':
                                dig = optarg;
                                break;
                        case 'v':
                                verify_opt = 1;
                                break;
                        case 's':
                                set_opt = 1;
                                break;
                        case 'l':
                                follow_links_opt = 1;
                                break;
                        case 'h':
                        default:
                                fprintf(stderr, "Usage: hasher [-r] [-d digest] [-s] [-v] [-h] [-l] files\n");
                                fprintf(stderr, "\t-r recursive\n\t-d digest (type -d help)\n\t-s set digest\n\t-v verify digest\n\t-h print this help\n\t-l follow symlinks\n");
                                exit(1);
                }
        }

        if(set_opt == 1 && verify_opt == 1) {
                fprintf(stderr, "set and verify options are mutually exclusive\n");
                return 1;
        }

        if(set_opt == 0 && verify_opt == 0) {
                fprintf(stderr, "set nor verify specified, doing dry run\n");
        }

        for(i=0; digest_types[i].name != NULL; i++) {
                if(strcmp(digest_types[i].name, dig) == 0) {
                        dig_alg = digest_types[i].type;
                        snprintf(attr_name, 100, "user.extattr-file-integrity.%s", digest_types[i].name);
                        break;
                }
        }

        if(dig_alg == GNUTLS_DIG_UNKNOWN) {
                if(strcmp(dig, "help")!=0) {
                        fprintf(stderr, "Unknown digest type %s\n", dig);
                }
                fprintf(stderr, "Available digests:");
                for(i=0; digest_types[i].name != NULL; i++) {
                        fprintf(stderr, " %s", digest_types[i].name);
                }
                fprintf(stderr, "\n");
                return 1;
        }

        if(optind == argc) {
                g_queue_push_tail(worknames, strdup("."));
        }

        while(optind < argc) {
                g_queue_push_tail(worknames, strdup(argv[optind++]));
                initqdepth++;
        }

        if(gnutls_hash_init(&digest, dig_alg)!=0) {
                fprintf(stderr, "Cannot init gnutls hash functions\n");
                return 1;
        }

        gnutls_hash_deinit(digest, NULL);

        return walk_dir(worknames, recursive);
}

int
is_dir(char *name) 
{
        struct stat sb;
        int ret;

        if(follow_links_opt) {
                ret = stat(name, &sb);
        } else {
                ret = lstat(name, &sb);
        }
        if(ret != 0) {
                fprintf(stderr, "error stating file %s ", name);
                perror(NULL);
                return -1;
        }
        return S_ISDIR(sb.st_mode);
}

int
walk_dir(GQueue *worknames, int recursive) 
{
        char *item;
        int ret;

        while((item=g_queue_pop_head(worknames))!=NULL) {
                if(initqdepth >= 0)
                        initqdepth--;
                ret = is_dir(item);
                if(ret == -1) {
                        fprintf(stderr, "Cannot stat %s\n", item);
                }
                if(ret == 0) {
                        process_file(item);
                }
                if(ret == 1) {
                        if(recursive || initqdepth >= 0) {
                                fprintf(stderr, "Walking down %s\n", item);
                                walk_down_dir(item, worknames);
                        } else {
                                fprintf(stderr, "%s is directory, skipped in non-recursive mode.\n", item);
                        }
                }
                free(item);
        }
        return 0;
}

void
set_hash(const char *name, const char *hash, int size)
{
        int ret;

        if(follow_links_opt) {
                ret = setxattr(name, attr_name, hash, size, 0);
        } else {
                ret = lsetxattr(name, attr_name, hash, size, 0);
        }

        if(ret != 0) {
                fprintf(stderr, "Cannot set xattr on %s ", name);
                perror("");
        }
}

void
verify_hash(const char *name, const char *hash, int size)
{
        char buff[size];
        int ret;

        if(follow_links_opt) {
                ret = getxattr(name, attr_name, buff, size);
        } else {
                ret = lgetxattr(name, attr_name, buff, size);
        }

        if(ret < 1) {
                fprintf(stderr, "Cannot get xattr on %s ", name);
                perror("");
                return;
        }

        if(memcmp(buff, hash, size) != 0) {
                fprintf(stderr, "Checksum ERROR on %s\n", name);
        } else {
                fprintf(stderr, "Checksum OK on %s\n", name);
        }
}

int
process_file(char *name) 
{
        FILE *in;
        char buff[16384];
        int usable=0;
        int ret;
        gnutls_hash_hd_t digest;
        int hash_len;
        unsigned char *hash;
        int i;

        gnutls_hash_init(&digest, dig_alg);

        hash_len = gnutls_hash_get_len(dig_alg);

        hash = calloc(1, hash_len);

        fprintf(stderr, "Processing %s...\n", name);
        in = fopen(name, "rb");

        if(!in) {
                fprintf(stderr, "Cannot open file ");
                perror(name);
                return -1;
        }

        while(!feof(in)) {
                ret = fread(buff, 1, 16384, in);
                if(ret < 1) {
                        break;
                }
                usable = 1;
                gnutls_hash(digest, buff, ret);
        }

        if(usable == 0) {
                return -1;
        }

        fclose(in);

        gnutls_hash_deinit(digest, hash);

        fprintf(stderr, "Hash: ");

        for(i=0; i < hash_len; i++) {
                fprintf(stderr, "%x", hash[i]);
        }

        fprintf(stderr, "\n");

        if(set_opt) {
                set_hash(name, (const char*)hash, hash_len);
        }

        if(verify_opt) {
                verify_hash(name, (const char*)hash, hash_len);
        }

        free(hash);

        return 0;
}

void
walk_down_dir(char *directory, GQueue *worknames) 
{
        DIR *dir;
        struct dirent *de;
        char buff[PATH_MAX+NAME_MAX];

        dir = opendir(directory);

        if(!dir) {
                perror(directory);
                return;
        }

        while((de = readdir(dir))) {
                if(strcmp(de->d_name, ".") == 0)
                        continue;
                if(strcmp(de->d_name, "..") == 0)
                        continue;
                snprintf(buff, PATH_MAX+NAME_MAX, "%s/%s", directory, de->d_name);
                fprintf(stderr, "Adding %s\n", buff);
                g_queue_push_head(worknames, strdup(buff));
        }

        closedir(dir);
}
