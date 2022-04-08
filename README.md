# ocado-orders
Script to parse Ocado confirmation emails into a CSV file for analysis

For newbie windows users
Install ruby from here: https://editrocket.com/articles/ruby_windows.html
*Requirements*
https://github.com/mikel/mail
https://nokogiri.org/index.html

From a terminal
* gem install nokogiri
* gem install mail

*To run:*
ruby ocado-orders-parse.rb

Changes
Added some protection against null pointer errors
Formatted the sells by date format to enable the creation of a pivot table by month in google sheets
Added the ability to work with emails saved as independent files in a folder
Added comments with some tips on getting this working with gmail
