VERSION = `date "+%Y.%m.%d_%H.%M.%S"`
TEMPLATES = $(wildcard \
	hearth/templates/*.html \
	public/templates/**/*.html \
)
STYL_FILES = $(wildcard \
	hearth/media/css/*.styl \
	public/media/css/**/*.styl \
)
CSS_FILES = $(STYL_FILES:.styl=.styl.css)
COMPILED_TEMPLATES = hearth/templates.js

compile: $(COMPILED_TEMPLATES) $(CSS_FILES)

fastcompile:
	node damper.js --compile

$(COMPILED_TEMPLATES): $(TEMPLATES)
	node damper.js --compile nunjucks

%.styl.css: %.styl
	node damper.js --compile stylus --path $<

l10n: compile
	cd locale ; \
	./omg_new_l10n.sh

langpacks:
	for po in `find locale -name "*.po"` ; do \
		node scripts/generate_langpacks.js $$po ; \
		mv $$po.js hearth/locales/`basename \`dirname \\\`dirname $$po\\\`\` | tr "_" "-"`.js ; \
	done

test: clean fastcompile
	cd smokealarm ; \
	casperjs test tests

package: compile
	cd hearth/ && zip -r ../$(VERSION).zip * && cd ../

log:
	cd yulelog && zip -r ../yulelog_$(VERSION).zip * && cd ../


clean:
	rm -f $(CSS_FILES)
	rm -f $(COMPILED_TEMPLATES)
	rm -f hearth/media/css/include.css
	rm -f hearth/media/js/include.*

includes: clean compile
	echo "/* $(VERSION) */" > hearth/media/include.css
	echo "/* $(VERSION) */" > hearth/media/include.js
	cat amd/amd.js >> hearth/media/include.js
	python build.py
	cleancss hearth/media/include.css > hearth/media/css/include.css
	rm -f hearth/media/include.css
	mv hearth/media/include.js hearth/media/js/
	#uglifyjs hearth/media/js/include.js -o hearth/media/js/include.js -m

lint:
	# You need closure-linter installed for this.
	gjslint --nojsdoc -r hearth/media/js/ -e lib

deploy:
	git fetch && git reset --hard origin/master && npm install && make includes
