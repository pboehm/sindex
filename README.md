# Sindex [![Build Status](https://secure.travis-ci.org/pboehm/sindex.png)](http://travis-ci.org/pboehm/sindex)

Sindex is a tool and library that manages an index file, which contains the tv
series and episodes you have watched. This index can be used by other
tools like `sjunkieex` to determine new episodes that you are interested in.
[Here](https://github.com/pboehm/sindex/blob/master/test/seriesindex_example.xml)
is an example, how an index looks like and what features are supported.

## Installation

`sindex` requires Ruby 1.9 to work, then you can install it through:

    $ [sudo] gem install sindex

You can configure `sindex` in `~/.sindex/config.yml` after initial
execution. The standard path for the episode index is
`~/.sindex/seriesindex.xml`.

## Dependencies

 - `nokogiri` is used for all the XML handling and requires that you have
   installed the C-libraries for `libxml2` and `libxslt` in their development
   version. Consult the documentation of `nokogiri` for further information.

## Usage

### Initial creation of an index

`sindex` allows you to build an index from a directory, that contains your
watched series and episodes. The directory from which the index is built,
should have the following structure:

    /path/to/your/series_directory/
    ├── Chuck
    │   └── .......
    ├── Community
    │   └── .......
    └── The Big Bang Theory
        └── .......

`sindex` treats all directories in your supplied directory as series, so you
should name they correct. In these directories, all Video-files (recursively)
containing `S0xE0x` are added for the series to the index. It is recommended to
rename your episode with a tool like
[serienrenamer](https://github.com/pboehm/serienrenamer), which renames your
episodes into this format.

The following command creates an index from the directory `/home/user/Serien`
and writes it to `/home/user/Desktop/index.xml`:

    $ sindex --buildindex ~/Serien --indexfile ~/Desktop/index.xml

If your episodes are not in German, you have to add `--language [en|fr]`. Now
you should make changes to the index if required and move this to the path
specified by `index_file`.

### Adding new episodes to the index

`sindex` wouldn't be useful without the option to add new episodes to the
index. If you have downloaded and renamed your new episodes, you can type only
`sindex` and a similar output can be viewed.

    [user@host ~]% ls ~/Downloads
    S04E21 - Kopfjäger.mkv
    [user@host ~]% sindex

    >>> S04E21 - Kopfjäger.mkv
    << from infostore: Castle
    << selected series name: Castle
    << language: de
    Added 'S04E21 - Kopfjäger.mkv' to index

    Should I write the new index? y
    New Index version has been written

After that, an updated version of the index is written to disk, which contains
the new episode.

## Hooks

`sindex` allows you to define three kinds of Hooks, that are executed at special places. You can supply Scripts or command lines to be executed as Hooks.

 * `pre_processing_hook` is called before the index is parsed on adding new
   episodes. This allows you to do a `git pull` on your version controlled
   series index or something else.
 * `post_processing_hook` is called when a new index is written. I use this
   to do a `git commit` and `git push` to save the index on Github.
 * `episode_hook` is called for every episode after a new index is written.
   The parameters are the filename (relative to `episode_directory`) and second
   the series name. I use this to move the episodes out of my Download folder
   into a special directory structure.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
