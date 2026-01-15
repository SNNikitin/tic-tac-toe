require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = 'TicTacToeNative'
  s.version      = package['version']
  s.summary      = 'TicTacToe native modules'
  s.homepage     = 'https://github.com/SNNikitin/tic-tac-toe/'
  s.license      = { :type => 'MIT' }
  s.author       = { 'Author' => 'tic-tac-toe@snnikitin.work' }
  s.source       = { :path => '.' }
  s.platform     = :ios, '15.0'
  s.swift_version = '6.0'

  s.source_files = [
    'core/Sources/**/*.swift',
    'rn/ios/*.{swift,h,mm}'
  ]
  s.private_header_files = 'rn/ios/*.h'
  s.library      = 'sqlite3'
  s.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++20',
    'DEFINES_MODULE' => 'YES'
  }

  install_modules_dependencies(s)
end
