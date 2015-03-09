# Build script for expat

do_expat_get() { :; }
do_expat_extract() { :; }
do_expat_for_build() { :; }
do_expat_for_host() { :; }
do_expat_for_target() { :; }

if [ "${CT_EXPAT}" = "y" -o "${CT_EXPAT_TARGET}" = "y" ]; then

do_expat_get() {
    # The server hosting expat will return an "HTTP 300 : Multiple Choices"
    # error code if we try to download a file that does not exists there.
    # So we have to request the file with an explicit extension.
    CT_GetFile "expat-${CT_EXPAT_VERSION}" .tar.gz http://downloads.sourceforge.net/project/expat/expat
}

do_expat_extract() {
    CT_Extract "expat-${CT_EXPAT_VERSION}"
    CT_Patch "expat" "${CT_EXPAT_VERSION}"
}

if [ "${CT_EXPAT}" = "y" ]; then

# Build expat for running on build
# - always build statically
# - we do not have build-specific CFLAGS
# - install in build-tools prefix
do_expat_for_build() {
    local -a expat_opts

    case "${CT_TOOLCHAIN_TYPE}" in
        native|cross)   return 0;;
    esac

    CT_DoStep INFO "Installing expat for build"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-expat-build-${CT_BUILD}"

    expat_opts+=( "host=${CT_BUILD}" )
    expat_opts+=( "prefix=${CT_BUILDTOOLS_PREFIX_DIR}" )
    expat_opts+=( "cflags=${CT_CFLAGS_FOR_BUILD}" )
    expat_opts+=( "ldflags=${CT_LDFLAGS_FOR_BUILD}" )
    expat_opts+=( "shared=n" )
    do_expat_backend "${expat_opts[@]}"

    CT_Popd
    CT_EndStep
}

# Build expat for running on host
do_expat_for_host() {
    local -a expat_opts

    CT_DoStep INFO "Installing expat for host"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-expat-host-${CT_HOST}"

    expat_opts+=( "host=${CT_HOST}" )
    expat_opts+=( "prefix=${CT_HOST_COMPLIBS_DIR}" )
    expat_opts+=( "cflags=${CT_CFLAGS_FOR_HOST}" )
    expat_opts+=( "ldflags=${CT_LDFLAGS_FOR_HOST}" )
    expat_opts+=( "shared=n" )
    do_expat_backend "${expat_opts[@]}"

    CT_Popd
    CT_EndStep
}

fi # CT_EXPAT

if [ "${CT_EXPAT_TARGET}" = "y" ]; then

do_expat_for_target() {
    local -a expat_opts

    CT_DoStep INFO "Installing expat for the target"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-expat-target-${CT_TARGET}"

    expat_opts+=( "destdir=${CT_SYSROOT_DIR}" )
    expat_opts+=( "host=${CT_TARGET}" )
    expat_opts+=( "prefix=/usr" )
    expat_opts+=( "shared=y" )
    do_expat_backend "${expat_opts[@]}"

    CT_Popd
    CT_EndStep
}

fi # CT_EXPAT_TARGET

# Build expat
#     Parameter     : description               : type      : default
#     destdir       : out-of-tree install dir   : string    : /
#     host          : machine to run on         : tuple     : (none)
#     prefix        : prefix to install into    : dir       : (none)
#     cflags        : cflags to use             : string    : (empty)
#     ldflags       : ldflags to use            : string    : (empty)
#     shared        : also buils shared lib     : bool      : n
do_expat_backend() {
    local destdir="/"
    local host
    local prefix
    local cflags
    local ldflags
    local shared
    local -a extra_config
    local arg

    for arg in "$@"; do
        eval "${arg// /\\ }"
    done

    CT_DoLog EXTRA "Configuring expat"

    if [ "${shared}" = "y" ]; then
        extra_config+=( --enable-shared )
    else
        extra_config+=( --disable-shared )
    fi

    CT_DoExecLog CFG                                        \
    CC="${host}-gcc"                                        \
    RANLIB="${host}-ranlib"                                 \
    CFLAGS="${cflags} -fPIC"                                \
    LDFLAGS="${ldflags}"                                    \
    "${CT_SRC_DIR}/expat-${CT_EXPAT_VERSION}/configure"     \
        --build=${CT_BUILD}                                 \
        --host=${host}                                      \
        --target=${CT_TARGET}                               \
        --prefix="${prefix}"                                \
        --enable-static                                     \
        "${extra_config[@]}"

    CT_DoLog EXTRA "Building expat"
    CT_DoExecLog ALL make

    CT_DoLog EXTRA "Installing expat"
    CT_DoExecLog ALL make instroot="${destdir}" install
}

fi # CT_EXPAT || CT_EXPAT_TARGET
