# Maintainer: Your Name <youremail@domain.com>

pkgname=openfast
pkgver=1.0.0
pkgrel=1
epoch=
pkgdesc="OpenFAST from NREL - wind turbine simulation code"
arch=('any') not certain
url="https://github.com/OpenFAST/${pkgname}"
license=('LICENSE-APACHE')
depends=(
	'lapack' 
	'blas' 
	'hdf5' 
	'yaml-cpp'
	)
makedepends=(
	'gcc-fortran>=6.1.0'
	'gcc' 
	'cmake >=2.8.12'
	)
checkdepends=()
optdepends=(
	'python>=3.0.0'
	)
provides=()
conflicts=()
replaces=()
backup=()
options=()
install=
changelog=
source=("${pkgname}-${pkgver}.tar.gz::https://github.com/OpenFAST/${pkgname}")
noextract=()
md5sums=()
validpgpkeys=()
build() {
	cd "$pkgname-$pkgver"
	git clone "https://github.com/OpenFAST/OpenFAST.git"
	cd OpenFAST
	mkdir build
	cd build
	cmake ../
	./configure --prefix=/usr
	make
}

check() {
	cd "$pkgname"
	make -k check
}

package() {
	cd "$pkgname"
	make DESTDIR="$pkgdir/" install
}
