#!/usr/bin/env ruby

=begin

Script to parse many Ocado confirmation emails into a single CSV file with one item per row
with structure: UNIX timestamp,"Product name",price
e.g.
1194212388,"Red Chillies Waitrose",0.69
1194212388,"Heinz Organic Baked Beans",0.65
1194212388,"Heinz Organic Baked Beans",0.65
1217098917,"UK Blackberries Waitrose",1.49

To use, save raw source of all order confirmation messages in one file (ocado-orders.txt)
e.g. in macOS Mail.app, search: from = customerservices@ocado.com + subject = Confirmation of your order
Select All, File > Save As ... > ocado-orders.txt (Format: Raw Message Source)

From gmail search "ocado "Confirmation of your order""
Set the date range appropriately
Select all mails
Select "Forward as attachement"
The resulting email contains all the ocado mails that cen be saved to a directory
=end

%w(mail nokogiri).each { |lib| require lib }

order_mails = Dir["./ocadoorders2021/*"]
msgs = []
order_mails.each do |mail|
  puts "reading: " + mail
  msgs_src = File.read mail
  msg = msgs_src.split(/\n(?=Return-Path:)/)[1 .. -1]
  msgs += msg
end

# first, find all unique final orders (i.e. the latest confirmation email for each order)

orders = {}

msgs.each do |msg_src|
  msg = Mail.new(msg_src)
  puts "parsed message"
  if(!msg.date.nil? )
    timestamp = msg.date.strftime("%d/%m/%Y")
    puts "timestamp"
    puts timestamp
    multipart = msg.parts.find { |p| p.content_type.start_with? 'multipart/alternative' }
    txt = multipart.parts.find { |p| p.content_type.start_with? 'text/plain' }.decoded
    ref = txt.match(/^Order ref.:\s*([0-9]+)/)[1].to_i

    # skip to next email if we've already stored a more recent confirmation for this order
    next if orders[ref] and orders[ref][:timestamp] > timestamp
    
    # use the HTML to find product details, because the plain text version used to lack prices
    html = multipart.parts.find { |p| p.content_type.start_with? 'text/html' }.decoded
    doc = Nokogiri::HTML(html)
    lines = doc.css('li > font').map(&:text).join("\n")
    products = lines.scan(/^([0-9]+)\s+(.+)\s+(\u00a3|&pound;)([0-9]+\.[0-9]{2})/).map { |p| {qty: p[0].to_i, name: p[1], price: p[3].to_f} }

    orders[ref] = {timestamp: timestamp, products: products}
  end
end

# second, expand orders out into products, one per line, with price and timestamp
# and save as CSV for analysis in R, Postgres, etc.

csv = ''

orders.each do |ref, order|
  order[:products].each do |product|
    product[:qty].times { csv << order[:timestamp].to_s + ',"' + product[:name].gsub('"', '""') + '",' + (product[:price] / product[:qty]).to_s + "\n" }
  end
end

File.write 'ocado-orders.csv', csv

