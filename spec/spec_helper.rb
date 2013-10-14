# We can't use `require` or `load` because of the Bash preamble on the script.
source = File.read(File.expand_path("../../selecta", __FILE__))
preamble, source = source.split("#!ruby", 2)
eval(source)
