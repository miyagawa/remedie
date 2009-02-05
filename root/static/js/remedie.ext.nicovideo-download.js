if (typeof remedie != 'undefined') {
    remedie.addAction(/nicovideo/, 'Download file via CGI', function(item) {
        if (/.*(sm[0-9]+)$/.test(item.ident)) {
            // NOTE: specify your script. you can get this script from WWW::NicoVideo::Download
            window.open("http://127.0.0.1/cgi-bin/nph-download-proxy.cgi/" + RegExp.$1);
        }
    });
}
