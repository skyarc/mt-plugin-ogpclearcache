package MT::Plugin::OGPClearCache;

use strict;
use warnings;
use base qw( MT::Plugin );
use constant ENDPOINT => 'https://graph.facebook.com/';
use JSON;

our $PLUGIN_NAME  = 'OGPClearCache';
our $VERSION = '0.1';

my $plugin = __PACKAGE__->new({
    name     => $PLUGIN_NAME,
    version  => $VERSION,
    key      => lc $PLUGIN_NAME,
    id       => lc $PLUGIN_NAME,
    schema_version => $VERSION,
    l10n_class  => $PLUGIN_NAME. '::L10N',
    author_name => qq{<__trans phrase="SKYARC Co.,Ltd.">},
    author_link => 'http://www.skyarc.co.jp/',
    plugin_link => 'https://github.com/skyarc/mt-plugin-ogpclearcache',
    doc_link    => 'http://www.mtcms.jp/',
    description => qq{<__trans phrase="ogp clear cache">},
    blog_config_template => \&_config_template,
    settings    => MT::PluginSettings->new([
        [ 'execute', +{
            Default => 0,
            Scope   => 'blog'
        }],
    ]),
});

sub init_registry {
     shift->registry({
        callbacks => {
            'cms_post_save.entry' => \&_cms_post_save_entry,
            'cms_post_save.page'  => \&_cms_post_save_entry,
        },
    });
}

MT->add_plugin($plugin) ;

sub _cms_post_save_entry {
    my ($cb, $app, $obj, $orig) = @_;
    return unless $app->isa('MT::App::CMS');

    my $config = $plugin->get_config_hash('blog:'.$obj->blog_id);
    return unless $config->{execute};

    my $ua = MT->new_ua;
    my $response = $ua->post(ENDPOINT(), Content => +{
            scrape => 'true',
            id     => $obj->permalink,
        }
    );

    unless ($response->is_success) {
        my $json = $response->content or return;
        my $json_decode = JSON->new->utf8->decode($json) or return;

        MT->log({
            blog_id  => $obj->blog_id,
            metadata => $obj->id,
            message  => $json_decode->{error}->{message},
            class    => 'MT::Log::Entry',
            level    => 'MT::Log::DEBUG',
        });
    }
}

sub _config_template {
    my ($plugin, $param, $scope) = @_;
    my $tmpl = <<__HTML__;
<mtapp:setting id="execute" label="<__trans phrase="execute">">
<input type="radio" name="execute" value="1" <mt:if name="execute">checked="checked"</mt:if> >ON
<input type="radio" name="execute" value="0" <mt:unless name="execute">checked="checked"</mt:unless> >OFF
</mtapp:setting>
__HTML__
    return $tmpl;
}
__END__
