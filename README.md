# Franklin

Franklin is a static-site framework, optimized for online books.

![Franklin Logo](https://cloud.githubusercontent.com/assets/1256329/10561173/fd1a8618-74ed-11e5-8add-a4b1b7d8381e.png)

## Setup

Franklin is built on top of [Middleman](http://middlemanapp.com/), a fantastic static site generator written in Ruby. The setup steps are as follows:

**1) Install Dependencies**

Ensure that you have the following installed:
* Ruby (comes pre-installed on Mac)
* Rubygems (comes pre-installed on Mac)
* Bundler (see http://bundler.io for installation instructions)

**2) Install Middleman**

```bash
# Run the following commands in the console
gem install middleman
```

For more detailed instructions, see http://middlemanapp.com/basics/getting-started/.

**3) Download this project, and place it in your ~/.middleman directory:**

```bash
# If you have git installed...
git clone git@github.com:bryanbraun/franklin.git ~/.middleman/bryanbraun/franklin
```

If you don't have [git](http://git-scm.com/) installed, you can manually [download franklin](https://github.com/bryanbraun/franklin/archive/master.zip), unzip it, and drop it into your `~/.middleman` folder.

**4) Create your project:**

```bash
# Replace 'mysite' with the name of your project
middleman init mysite --template=bryanbraun/franklin
cd mysite
bundle install  # Installs any franklin-specific gems.
```

## Basic Usage

The most basic purpose of Franklin is to convert a stack of markdown files into an HTML site, and to do it in a way that is optimized for books.

Your markdown files go into the "source" folder. They can be named anything (`xxxxxxxx.md`), except you must have a file named `index.md` to serve as the front page of your book. Franklin starts you out with some example files, which you can change or remove to suit your needs.

The structure of your book, as given in the Table of Contents, will mimic the structure of the markdown files in the source directory. Notably:

1. Your front page (`index.md`) will be promoted to the top of the list.
2. Pages will be ordered alphebetically by their file names (thus, using a numbered prefix, like `01-my-filename.md` is encouraged).
3. Your readme (`readme.md`) file will not appear in your table of contents (for guidence on how to exclude other items from the Table of Contents, see the README for the [Middleman-Navtree](https://github.com/bryanbraun/middleman-navtree) gem).

When you are ready to build your site, run the following command:
```bash
# This creates a `build` folder, containing your site, converted into static HTML.
bundle exec middleman build
```
Using Middleman's customization options, you can do all sorts of interesting things beyond this basic use-case. For details, see the [Middleman documentation](http://middlemanapp.com/).

## Configuration

#### `book.yml`

This is where you can change the author, title, and other book information. The available parameters are (with example values):

```yaml
title: Example Book
author: You
github_url: https://github.com/yourname/example-book
domain: http://yourname.github.io/example-book
license_name: Attribution-ShareAlike
license_url: https://creativecommons.org/licenses/by-sa/4.0
```

#### `tree.yml`

This defines the order and structure of your book (for the table of contents and pagination). This file is generated automatically and should not need adjustment. For advanced use-cases where adjustment is desired, see the [middleman-navtree docs](https://github.com/bryanbraun/middleman-navtree) (specifically the `automatic_tree_updaets` option).

## Themes

Themes can be found in the `source/themes` directory. You can use your own theme by adding it to the `themes` folder and changing the value in `config.rb`: like so:

```ruby
config[:theme] = 'glide'
```

Any theme you add must have the following structure:

```
theme_name
  |
  |--javascripts
  |
  |--layouts
  |
  `--stylesheets
```

The main page layout is defined in `layouts/layout.erb`. For more details on working with layouts, see [Middleman's documentation](http://middlemanapp.com/basics/templates/#layouts).

## Localization

Default locale is `:en`. If you want to change it, for example to `:pl`, configure middleman:

    activate :i18n, :mount_at_root => :pl

and put locales file `pl.yml` in `locales` directory in format:

    ---
      pl:
        previous_page: 'Poprzednia'
        next_page: 'Następna'
        table_of_contents: 'Spis treści'

## Examples
![Screenshot of three mobile-friendly Franklin themes](https://cloud.githubusercontent.com/assets/1256329/15450713/3ed30728-1f71-11e6-8a1b-eb3d9c014699.png)

  - [Epsilon Theme Example](http://bitbooks.github.io/example-book-epsilon/)
  - [Glide Theme Example](http://bitbooks.github.io/example-book-glide/)
  - [Hamilton Theme Example](http://bitbooks.github.io/example-book-hamilton/)

## Contribution Guidelines

1. [Fork this project](https://github.com/bryanbraun/franklin/fork)
2. Create a feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch to github (`git push origin my-new-feature`)
5. Submit a Pull Request

## Contributors

(If you are making a contribution, add your name here as part of your pull request)

## License
[MIT](http://opensource.org/licenses/MIT)
