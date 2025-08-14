# Maintainer: Your Name <your.email@example.com>
pkgname=nvm-fish
pkgver=1.0.0
pkgrel=1
pkgdesc="Fish shell integration for Node Version Manager (nvm)"
arch=('any')
url="https://github.com/nvm-sh/nvm"
license=('MIT')
depends=('nvm' 'fish' 'bass')
makedepends=()
source=("nvm.fish"
        "nvm_find_nvmrc.fish"
        "load_nvm.fish")
sha256sums=('SKIP'
            'SKIP'
            'SKIP')

package() {
    # 创建fish函数目录
    install -d "${pkgdir}/usr/share/fish/vendor_functions.d/"
    
    # 安装fish函数文件
    install -m644 "${srcdir}/nvm.fish" "${pkgdir}/usr/share/fish/vendor_functions.d/"
    install -m644 "${srcdir}/nvm_find_nvmrc.fish" "${pkgdir}/usr/share/fish/vendor_functions.d/"
    install -m644 "${srcdir}/load_nvm.fish" "${pkgdir}/usr/share/fish/vendor_functions.d/"
}