REMOTES = {
   'https://packages.dargon.io' => {
      'remote_ip' => 'x.y.z.w',
      'remote_user' => 'warty',
      'remote_key' => 'priv_key (priv_key.pub must exist!!!)',
      'remote_nest_root' => '/var/www/io.dargon.packages'
   }
};

SIGNING = {
   'signtool_path' => 'C:/path/to/signtool.exe',
   'pfx_path' => 'C:/path/to/file.pfx',
   'timestamp_url' => 'http://timestamp.verisign.com/scripts/timstamp.dll'
}
