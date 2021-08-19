# frozen_string_literal: true

task default: :run

task :run do
  ruby 'zelda.rb'
end

task :test do
  FileList['tests/*.rb'].each do |file|
    ruby file
  end
end
