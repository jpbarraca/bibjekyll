# This plugin interfaces bibtex2html (http://www.lri.fr/~filliatr/bibtex2html/) with Jekyll
# to generate an html bibliography list from bibtex entries.
# For this to work, the bibtex entries must be enclosed in a special liquid block:
# {% bibtex style.bst %}
#   ....
# {% endbibtex %}

module Jekyll
  # Workaround for commit 5b680f8dd80aac1 in jekyll (remove orphaned files in destination)
  # that deletes all the files created by plugins.
  class Site
    def cleanup
    end
  end

  class BibtexTag < Liquid::Tag
    # The options that are passed to bibtex2html
    Options = "-nofooter -noheader -nokeys -use-table -nokeywords -nodoc -dl"

    def split_params(params)
      params.split(" ").map(&:strip)
    end

    def initialize(tag_name, params, tokens)
      super
      args = split_params(params)
      @style = args[0]
      @bibfile = args[1]
      p "Processing: " + @bibfile 
    end

    def render(context)
       
      bib = @bibfile 

      # get the complete paths for the style file and the source file
      stylepath = File.join(context['site']['source'], @style)
      file = File.join(context['site']['destination'],context['page']['url'])
      dirname = File.dirname(file)

      # ensure that the destination directory exists
      FileUtils.mkdir_p(dirname)

      # enter the destination directory
      Dir.chdir(dirname) do
        basename = File.basename(bib).split('.')[-2]
	# file generated by bibtex2html that shall be included into the generated page
        outname = basename + ".html"
	# file containing bib entries (also generated by bibtex2html)
        bibhtml = basename + "_bib.html"

        # call bibtex2html
        system("bibtex2html #{Options} -s #{stylepath} -o #{basename} #{bib}")

	if File.exists?(bibhtml)
	  # Read html formated bib file
          content_bibhtml = IO.read(bibhtml)
	  # determine the name of the file we are generating
	  page = File.basename(file).split('.')[-2]
	  # replace links to basename by page
	  content_bibhtml = content_bibhtml.gsub(basename, page)
	  # commit changes
	  File.open(bibhtml, 'w') {|f| f.write(content_bibhtml)}
	end

        # return the produced output
        IO.read(outname)
      end
    end
  end
end
Liquid::Template.register_tag('bibtex', Jekyll::BibtexTag)
