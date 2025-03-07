#! /bin/sh
set -eux;
cd /build;

GNUPGHOME="$(mktemp -d)"; export GNUPGHOME;
gpg --import /out/python-gpg-key;
gpg --batch --verify /out/python.tar.xz.asc python.tar.xz;
rm /out/python-gpg-key;
rm /out/python.tar.xz.asc;

tar -xaf python.tar.xz --strip-components=1;
gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)";
   
cp /out/setuptools-75.8.0-py3-none-any.whl /build/Lib/ensurepip/_bundled/;
cp /out/pip-25.0.1-py3-none-any.whl /build/Lib/ensurepip/_bundled/;

sed -i "s/_SETUPTOOLS_VERSION = \".*\"/_SETUPTOOLS_VERSION = \"75.8.0\"/g" /build/Lib/ensurepip/__init__.py;
sed -i "s/_PIP_VERSION = \".*\"/_PIP_VERSION = \"25.0.1\"/g" /build/Lib/ensurepip/__init__.py;

./configure --prefix="/out/opt/python-${PYTHON_VERSION}" \
    --build="$gnuArch" \
    --enable-loadable-sqlite-extensions \
    --enable-option-checking=fatal \
    --enable-shared \
    --with-lto \
    --with-ensurepip;

nproc="$(nproc)";
EXTRA_CFLAGS="-DTHREAD_STACK_SIZE=0x100000";
LDFLAGS="${LDFLAGS:--Wl},--strip-all";
EXTRA_CFLAGS="${EXTRA_CFLAGS:-} -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer";
make -j "$nproc" "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" "LDFLAGS=${LDFLAGS:-}";
rm python;
make -j "$nproc" "EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" "LDFLAGS=${LDFLAGS:--Wl},-rpath='\$\$ORIGIN/../lib'" python;

make install;

# replace invalid reference to /out directory
find /out/opt/python-${PYTHON_VERSION}/bin -type f -exec sed -i "s|/out/|/|g" {} +;

ln -s python3 /out/opt/python-${PYTHON_VERSION}/bin/python;
ln -s pip3 /out/opt/python-${PYTHON_VERSION}/bin/pip;
ln -s python3-config /out/opt/python-${PYTHON_VERSION}/bin/python-config;
ln -s idle3 /out/opt/python-${PYTHON_VERSION}/bin/idle;
ln -s pydoc3 /out/opt/python-${PYTHON_VERSION}/bin/pydoc;