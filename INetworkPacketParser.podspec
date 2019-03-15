#
# Be sure to run `pod lib lint INetworkPacketParser.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'INetworkPacketParser'
  s.version          = '0.1.0'
  s.summary          = 'ip packet, tcp, udp and dns parser'
  s.description      = <<-DESC
1. support ip pacekt parser
2. support tcp / udp parser
3. support dns parser
                       DESC

  s.homepage         = 'https://github.com/smallyou/INetworkPacketParser'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'smallyou' => 'smallyou@126.com' }
  s.source           = { :git => 'https://github.com/smallyou/INetworkPacketParser.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.libraries = 'resolv'

  s.source_files = 'INetworkPacketParser/Classes/**/*'
end
