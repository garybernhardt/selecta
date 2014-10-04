# We can't use `require` or `load` because of the Bash preamble on the script.
source = File.read(File.expand_path("../../selecta", __FILE__))
source = source.split("#!ruby", 2).last
eval(source)
