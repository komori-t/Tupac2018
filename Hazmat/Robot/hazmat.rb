# export GOOGLE_APPLICATION_CREDENTIALS=/home/nvidia/Documents/Tupac2018-30b5beee9203.json
require "google/cloud/vision"
vision = Google::Cloud::Vision.new project: "Tupac2018"
image = vision.image "#{ARGV[0]}"
text = image.text
exit 0 if text == nil
lines = text.text.split "\n"
lines.each do |l|
    next if l =~ /\d/
    # string = l.gsub(/\d+/, "")
    # words = text.words
    print l, " "
    # words.each do |w|
    #     next if w.text =~ /\d/
    #     w.bounds.each do |b|
    #         print "#{b.x},#{b.y},"
    #     end
    # end
end
print "\n"
