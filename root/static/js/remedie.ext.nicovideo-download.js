if (typeof remedie != 'undefined') {
    remedie.addAction(/nicovideo/, 'Download Video', function(item) {
        if (/.*(sm[0-9]+)$/.test(item.ident)) {
            window.open("/action/nph-download-proxy.cgi/" + RegExp.$1);
        }
    });
}
