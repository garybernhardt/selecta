# We can't use `require` or `load` because of the Bash preamble on the script.
source = File.read(File.expand_path("../../selecta", __FILE__))
_preamble, source = source.split(/#!.*$/)
eval(source)
