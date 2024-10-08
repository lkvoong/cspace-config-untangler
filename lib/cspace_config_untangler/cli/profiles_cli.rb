require_relative 'helpers'

module CspaceConfigUntangler
  module Cli
    class ProfilesCli < Thor
      include CCU::Cli::Helpers
      desc 'all', 'Print the names of all known profiles to screen'
      def all
        say([CCU.main_profile, CCU.profiles].flatten.uniq.sort.join("\n"))
      end

      desc 'check', 'Prints to screen the names of profiles that will be processed'
      def check
        profiles = get_profiles
        say(profiles.join("\n"))
      end

      desc 'compare', 'Outputs a comparison of two profiles in CSV format'
      long_desc <<~LONGDESC
Requires two (and only two) profiles be specified with -p/--profile option:

> $ exe/ccu profiles compare -p core_6_1_0,anthro_4_1_2

The output CSV filename is generated by CCU.

The filename for the above will be: `compare_core_6_1_0_to_anthro_4_1_2.csv`.

You will find the csv file in the output directory you specified, or in the default directory shown above if you did not specify an output location. Examples of specifying custom output location below. Either form will work:

> $ exe/ccu profiles compare -p core_6_1_0,anthro_4_1_2 -o ~/files

> $ exe/ccu profiles compare -p core_6_1_0,anthro_4_1_2 -o /Users/you/files
LONGDESC
      option :output, desc: 'Path to directory in which to output file. Name of the file is hardcoded, using the names of the profiles.', default: CCU::datadir, aliases: '-o'
      def compare
        profiles = get_profiles
        
        if profiles.length > 2
          say('Can only compare two profiles at a time')
        elsif profiles.length == 1
          say('Needs two profiles to compare')
        else
          comparer = CCU::ProfileComparison.new(profiles, options[:output])
          comparer.write_csv
          message = "#{comparer.summary}\n\nWrote detailed report to: #{comparer.output}"
          say(message)
        end
      end

      desc 'by_extension', 'List all extensions used in profiles, and list which profile uses each'
      def by_extension
        exts = {}
        get_profiles.each{ |p|
          CCU::Profile.new(profile: p).extensions.each{ |ext|
            if exts.has_key?(ext)
              exts[ext] << p
            else
              exts[ext] = [p]
            end
          }
        }
        exts.keys.sort.each do |ext|
          puts ext
          exts[ext].each{ |p| puts "  #{p}" }
        end
      end

      desc 'main', 'Print the name of the main profile'
      def main
        say(CCU.main_profile)
      end

      desc 'readable', 'Reformats (in place) JSON profile configs so that they are not one very long line. Non-destructive if run over JSON multiple times.'
      def readable
        message = []
        get_profiles.each{ |p|
          message << "Reformatting #{p} config"
          oldprofile = JSON.parse(File.read("#{CCU.configdir}/#{p}.json"))
          File.open("#{CCU.configdir}/#{p}.json", 'w'){ |f|
            f.puts JSON.pretty_generate(oldprofile)
          }
        }
        say(message.join("\n"))
      end
    end
  end
end
