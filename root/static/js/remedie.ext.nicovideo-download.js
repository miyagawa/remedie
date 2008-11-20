if (typeof remedie != 'undefined') {
    remedie.addAction(/nicovideo/, 'Download Video', function(item) {
        if (/.*(sm[0-9]+)$/.test(item.ident)) {
            // TODO better to run on remedie's http server. 
            window.open("http://localhost:8080/nph-download-proxy.cgi/" + RegExp.$1);
        }
    });
}
