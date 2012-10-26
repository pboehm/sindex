# Sindex

Sindex is a tool and library that manages an index file, which contains the tv
series and episodes you have been watched. This index can be used by other
tools like `sjunkieex` to determine new episodes that you are interested in.

## Installation

Add this line to your application's Gemfile:

    gem 'sindex'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sindex

## Dependencies

 - `nokogiri` is used for all the XML handling and requires that you have
   installed the C-libraries for `libxml2` and `libxslt` in their development
   version. Consult the documentation of `nokogiri` for further information.

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
