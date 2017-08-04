require 'json'
package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name          = package['name']
  s.version       = package["version"]
  s.summary       = package['description']
  s.author        = { 'Vito CHEN' => 'gameboyvito@gmail.com' }
  s.license       = package['license']
  s.homepage      = package['homepage']
  s.source        = { :git => 'https://github.com/gameboyVito/aliyun-oss-react-native-sdk' }
  s.platform      = :ios, '8.0'

  s.source_files  = 'ios/*.{h,m}'

  s.dependency 'React'
  s.dependency 'AliyunOSSiOS', '~> 2.6.2'

end
