module.exports = function() {
    return {
        getAbsUrl: function(url) {
            if (url.match(/^.{2,5}:\/\//)) return url;
            if (url[0] === '/') return document.location.protocol + '//' + document.location.host + url;
            var base_url = document.location.protocol + '//' + document.location.host + document.location.pathname;
            if (base_url[base_url.length - 1] != '/' && url[0] != '#') return base_url + '/' + url;
            return base_url + url;
        },
        replaceParam: function(param, rep, rep2) {
            param = param.replace(/\{\{(.*?)\}\}/g, function(m, v) {
                return rep[v] || "";
            });
            if (rep2) param = param.replace(/\{(.*?)\}/g, function(m, v) {
                return rep2[v] || "";
            });
            return param;
        }
    };
}