(function() {
    var languages = {
        js: 'Javascript',
        ios: 'IOS',
        android: 'Android'
    }

    function TryIt(selector, settings) {
        selector.prepend('<div class="toolbar"></div><pre><code></pre></code>')

        this.selector = selector
        this.toolbar = selector.find('.toolbar')
        this.sample = selector.find('pre code')
        this.currentProvider = settings.providers[0]
        this.currentLanguage = settings.languages[0]
        this.settings = settings

        var that = this
        settings.providers.each(function(provider) {
            var state = 'black'
            if (that.currentProvider == provider) state = 'active'

            that.toolbar.append('<img class="tryit-provider" data-provider="' + provider + '" width="32" src="/img/homepageicon/' + provider + state + '.png" alt="">')
        })

        if (settings.languages.length > 1) {
            var content = '<div class="btn-group pull-right">\
                <button type="button" class="btn btn-xs btn-inverse dropdown-toggle" data-toggle="dropdown">\
                    <span class="text">' + languages[settings.languages[0]] + '</span> <span class="caret"></span>\
                </button>\
                <ul class="dropdown-menu" role="menu">\
                </ul>\
            </div>'
            this.toolbar.append(content)
            var langMenu = this.toolbar.find('.dropdown-menu')
            settings.languages.each(function(lang) {
                langMenu.append('<li><a href="#">' + languages[lang] + '</a></li>')
            })
        }
        if (settings.tryButton) {
            selector.append('<button class="btn btn-block btn-try">Try it</button>')
            selector.find('.btn-block').click(function() {
                if (settings.tryIt)
                    settings.tryIt(that.currentLanguage, that.currentProvider)
            })
        }

        that.fetch()
    }

    TryIt.prototype.fetch = function() {
        var that = this
        $.get(this.settings.url, {}, function(data) {
            that.data = data

            that.renderCode()

            that.toolbar.find('img.tryit-provider').click(function() {
                var newProvider = $(this).attr('data-provider')
                if (newProvider == that.currentProvider)
                    return false

                that.toolbar.find('img[data-provider=' + that.currentProvider + ']').attr('src', '/img/homepageicon/' + that.currentProvider + 'black.png')
                that.toolbar.find('img[data-provider=' + newProvider + ']').attr('src', '/img/homepageicon/' + newProvider + 'active.png')
                that.currentProvider = newProvider
                that.renderCode()
            })
            that.toolbar.find('.dropdown-menu li').click(function() {
                var strLang = $(this).text()
                var lang = null

                for (l in languages) {
                    if (languages[l] == strLang) {
                        lang = l
                        break
                    }
                }
                that.currentLanguage = lang
                that.toolbar.find('.dropdown-toggle .text').text(strLang)
                that.renderCode()
            })
        }, 'json')
    }

    TryIt.prototype.renderCode = function() {
        var that = this
        if (that.data[that.currentLanguage] && that.data[that.currentLanguage][that.currentProvider]) {
            content = that.data[that.currentLanguage][that.currentProvider]
            if (typeof content == 'string') {
                that.sample.html(that.data[that.currentLanguage][that.currentProvider])
                hljs.highlightBlock(that.sample[0])
            }
            else {
                if ( ! content.base) {
                    content.base = [that.currentLanguage, that.settings.providers[0]]
                }
                var c = that.data[content.base[0]][content.base[1]]
                for (r in content.replace) {
                    c = c.replace(new RegExp(content.replace[r], 'g'), content.by[r])
                }
                that.data[that.currentLanguage][that.currentProvider] = c
                that.renderCode()
            }

        }
    }

    var instances = []
    jQuery.fn.tryIt = function( options ) {
        // Bob's default settings:
        var defaults = {
            url: '/data/sampleCode.json',
            providers: ['facebook', 'twitter', 'google'],
            languages: ['js', 'ios', 'android'],
            tryButton: true,
            tryIt: function(provider, lang) {}
        };
        var settings = $.extend( {}, defaults, options );
        return this.each(function() {
            instances.push(new TryIt($(this), settings))
        });
    };
})();