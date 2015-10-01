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

int quiet=0;

int *digests;
int n_digests = sizeof digest_types / sizeof(struct digest_t);

int is_dir(char *name);
int walk_dir(GQueue *worknames, int recursive);
int process_file(char *name);
int walk_down_dir(char *directory, GQueue *worknames);

int
main(int argc, char *argv[])
{
        GQueue *worknames=g_queue_new();
        char recursive=0;
        int opt;
        int dig=0;
        int i;
        gnutls_hash_hd_t digest;

        digests = calloc(n_digests+1, sizeof(int));

        while((opt = getopt(argc, argv, "rd:svlhq")) != -1) {
                switch(opt) {
                        case 'r':
                                recursive = 1;
                                break;
                        case 'd':
                                if(strcmp(optarg, "help") == 0) {
                                        fprintf(stderr, "Available digests:");
                                        for(i=0; digest_types[i].name != NULL; i++) {
                                                fprintf(stderr, " %s", digest_types[i].name);
                                        }
                                        fprintf(stderr, "\n");
                                        return 0;
                                }
                                for(i=0; digest_types[i].name != NULL; i++) {
                                        if(strcmp(digest_types[i].name, optarg) == 0) {
                                                digests[dig++] = i;
                                                if(dig >= n_digests) {
                                                        fprintf(stderr, "Too many digests requested.\n");
                                                        return 1;
                                                }
                                                if(gnutls_hash_init(&digest, digest_types[i].type)!=0) {
                                                        fprintf(stderr,
                                                                  "Cannot init gnutls hash functions\n");
                                                        return 1;
                                                }
                                                gnutls_hash_deinit(digest, NULL);
                                                break;
                                        }
                                }
                                if(digest_types[i].name == NULL) {
                                        fprintf(stderr, "Unknown digest type %s\n", optarg);
                                        return 1;
                                }
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
                        case 'q':
                                quiet=1;
                                break;
                        case 'h':
                        default:
                                fprintf(stderr, "Usage: hasher [-r] [-d digest [-d digest ...]] [-s] [-v] [-h] [-l] [-q] files\n");
                                fprintf(stderr, "\t-r recursive\n\t-d digest (type -d help)\n\t-s set digest\n\t-v verify digest\n\t-h print this help\n\t-l follow symlinks\n\t-q quiet\n");
                                exit(1);
                }
        }

        n_digests=dig;
        digests[dig] = -1;

        if(set_opt == 1 && verify_opt == 1) {
                fprintf(stderr, "set and verify options are mutually exclusive\n");
                return 1;
        }

        if(set_opt == 0 && verify_opt == 0 && !quiet) {
                fprintf(stderr, "set nor verify specified, doing dry run\n");
        }

        if(optind == argc) {
                g_queue_push_tail(worknames, strdup("."));
        }

        while(optind < argc) {
                g_queue_push_tail(worknames, strdup(argv[optind++]));
                initqdepth++;
        }

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
                if(!quiet)
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
        int err_code=0;

        while((item=g_queue_pop_head(worknames))!=NULL) {
                if(initqdepth >= 0)
                        initqdepth--;
                ret = is_dir(item);
                if(ret == -1 && !quiet) {
                        fprintf(stderr, "Cannot stat %s\n", item);
                        err_code = -1;
                }
                if(ret == 0) {
                        if(process_file(item)!=0)
                                err_code = -1;
                }
                if(ret == 1) {
                        if(recursive || initqdepth >= 0) {
                                if(!quiet)
                                        fprintf(stderr, "Walking down %s\n", item);
                                if(walk_down_dir(item, worknames)!=0)
                                        err_code=-1;
                        } else {
                                if(!quiet)
                                        fprintf(stderr,
                                                "%s is directory, skipped in non-recursive mode.\n", item);
                        }
                }
                free(item);
        }
        return err_code;
}

int
set_hash(const char *name, const char *hash, int size, int dig)
{
        int ret;
        char attr_name[100];

        snprintf(attr_name, 100, "user.extattr-file-integrity.%s", digest_types[dig].name);

        if(follow_links_opt) {
                ret = setxattr(name, attr_name, hash, size, 0);
        } else {
                ret = lsetxattr(name, attr_name, hash, size, 0);
        }

        if(ret != 0 && !quiet) {
                fprintf(stderr, "Cannot set xattr on %s ", name);
                perror("");
                return -1;
        }
        return 0;
}

int
verify_hash(const char *name, const char *hash, int size, int dig)
{
        char buff[size];
        int ret;

        char attr_name[100];

        snprintf(attr_name, 100, "user.extattr-file-integrity.%s", digest_types[dig].name);

        if(follow_links_opt) {
                ret = getxattr(name, attr_name, buff, size);
        } else {
                ret = lgetxattr(name, attr_name, buff, size);
        }

        if(ret < 1 && !quiet) {
                fprintf(stderr, "Cannot get xattr on %s ", name);
                perror("");
                return -1;
        }

        if(memcmp(buff, hash, size) != 0) {
                if(!quiet)
                        fprintf(stderr, "Checksum ERROR on %s\n", name);
                return -1;
        } else {
                if(!quiet)
                        fprintf(stderr, "Checksum OK on %s\n", name);
        }
        return 0;
}

int
process_file(char *name)
{
        FILE *in;
        char buff[16384];
        int usable=0;
        int ret;
        gnutls_hash_hd_t digest[n_digests];
        int hash_len[n_digests];
        unsigned char *hash[n_digests];
        int i,j;
        int err_code=0;

        for(i=0; i < n_digests; i++) {
                gnutls_hash_init(&digest[i], digest_types[digests[i]].type);

                hash_len[i] = gnutls_hash_get_len(digest_types[digests[i]].type);

                hash[i] = calloc(1, hash_len[i]);
        }

        if(!quiet)
                fprintf(stderr, "Processing %s...\n", name);
        in = fopen(name, "rb");

        if(!in) {
                if(!quiet) {
                        fprintf(stderr, "Cannot open file ");
                        perror(name);
                }
                return -1;
        }

        while(!feof(in)) {
                ret = fread(buff, 1, 16384, in);
                if(ret < 1) {
                        break;
                }
                usable = 1;
                for(i=0; i < n_digests; i++)
                        gnutls_hash(digest[i], buff, ret);
        }

        if(usable == 0) {
                return -1;
        }

        fclose(in);

        for(i=0; i < n_digests; i++) {
                gnutls_hash_deinit(digest[i], hash[i]);

                if(!quiet) {
                        fprintf(stderr, "Hash %s: ", digest_types[digests[i]].name);

                        for(j=0; j < hash_len[i]; j++) {
                                fprintf(stderr, "%x", hash[i][j]);
                        }

                        fprintf(stderr, "\n");
                }

                if(set_opt) {
                        if(set_hash(name, (const char*)hash[i], hash_len[i], digests[i])!=0)
                                err_code=-1;
                }

                if(verify_opt) {
                        if(verify_hash(name, (const char*)hash[i], hash_len[i], digests[i])!=0)
                                err_code=-1;
                }

                free(hash[i]);
        }

        return err_code;
}

int
walk_down_dir(char *directory, GQueue *worknames)
{
        DIR *dir;
        struct dirent *de;
        char buff[PATH_MAX+NAME_MAX];

        dir = opendir(directory);

        if(!dir) {
                perror(directory);
                return -1;
        }

        while((de = readdir(dir))) {
                if(strcmp(de->d_name, ".") == 0)
                        continue;
                if(strcmp(de->d_name, "..") == 0)
                        continue;
                snprintf(buff, PATH_MAX+NAME_MAX, "%s/%s", directory, de->d_name);
                if(!quiet)
                        fprintf(stderr, "Adding %s\n", buff);
                g_queue_push_head(worknames, strdup(buff));
        }

        closedir(dir);
        return 0;
}
