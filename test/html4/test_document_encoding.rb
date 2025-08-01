# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "helper"

class TestNokogiriHtmlDocument < Nokogiri::TestCase
  describe "Nokogiri::HTML4::Document" do
    describe "Encoding" do
      def test_encoding
        doc = Nokogiri::HTML4(File.open(SHIFT_JIS_HTML, "rb"))

        hello = "こんにちは"

        assert_match(doc.encoding, doc.to_html)
        assert_match(hello.encode("Shift_JIS"), doc.to_html)
        assert_equal("Shift_JIS", doc.to_html.encoding.name)

        assert_match(hello, doc.to_html(encoding: "UTF-8"))
        assert_match("UTF-8", doc.to_html(encoding: "UTF-8"))
        assert_match("UTF-8", doc.to_html(encoding: "UTF-8").encoding.name)
      end

      def test_encoding_without_charset
        doc = Nokogiri::HTML4(File.open(SHIFT_JIS_NO_CHARSET, "r:Shift_JIS:Shift_JIS").read)

        hello = "こんにちは"

        assert_match(hello, doc.content)
        assert_match(hello, doc.to_html(encoding: "UTF-8"))
        assert_match("UTF-8", doc.to_html(encoding: "UTF-8").encoding.name)
      end

      def test_default_to_encoding_from_string
        bad_charset = <<~eohtml
          <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
          <html>
          <head>
            <meta http-equiv="Content-Type" content="text/html; charset=charset=UTF-8">
          </head>
          <body>
            <a href="http://tenderlovemaking.com/">blah!</a>
          </body>
          </html>
        eohtml
        doc = Nokogiri::HTML4(bad_charset)
        assert_equal(bad_charset.encoding.name, doc.encoding)

        doc = Nokogiri.parse(bad_charset)
        assert_equal(bad_charset.encoding.name, doc.encoding)
      end

      def test_encoding_non_utf8
        orig = "日本語が上手です"
        bin = Encoding::ASCII_8BIT
        [Encoding::Shift_JIS, Encoding::EUC_JP].each do |enc|
          html = <<~eohtml.encode(enc)
            <html>
            <meta http-equiv="Content-Type" content="text/html; charset=#{enc.name}">
            <title xml:lang="ja">#{orig}</title></html>
          eohtml
          text = Nokogiri::HTML4.parse(html).at("title").inner_text
          assert_equal(
            orig.encode(enc).force_encoding(bin),
            text.encode(enc).force_encoding(bin),
          )
        end
      end

      def test_encoding_with_a_bad_name
        bad_charset = <<~eohtml
          <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
          <html>
          <head>
            <meta http-equiv="Content-Type" content="text/html; charset=charset=UTF-8">
          </head>
          <body>
            <a href="http://tenderlovemaking.com/">blah!</a>
          </body>
          </html>
        eohtml
        doc = Nokogiri::HTML4(bad_charset, nil, "askldjfhalsdfjhlkasdfjh")
        assert_equal(
          ["http://tenderlovemaking.com/"],
          doc.css("a").map { |a| a["href"] },
        )
      end

      def test_empty_doc_encoding
        encoding = "US-ASCII"
        assert_equal(encoding, Nokogiri::HTML4.parse(nil, nil, encoding).encoding)
      end

      def test_bad_encoding_recovery
        # https://gitlab.gnome.org/GNOME/libxml2/-/issues/543
        skip if Nokogiri.uses_libxml?([">= 2.11.0", "< 2.12.0"])

        # https://gitlab.gnome.org/GNOME/libxml2/-/issues/947
        skip if Nokogiri.uses_libxml?([">= 2.14.0", "< 2.14.5"])

        html = <<~HTML
          <html>
            <head>
              <title>テスト</title>
              <meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">
            </head>
            <body>
              <div>hello</div>
            </body>
          </html>
        HTML

        refute_nil Nokogiri::HTML4.parse(html, encoding: "Shift_JIS")
        if Nokogiri.uses_libxml?
          assert_raises(Nokogiri::XML::SyntaxError) do
            Nokogiri::HTML4.parse(html, encoding: "Shift_JIS", options: Nokogiri::XML::ParseOptions::STRICT)
          end
        end
      end

      describe "Detection" do
        def binread(file)
          File.binread(file)
        end

        def binopen(file)
          File.open(file, "rb")
        end

        it "handles both memory and IO" do
          from_stream = Nokogiri::HTML4(binopen(NOENCODING_FILE))
          from_string = Nokogiri::HTML4(binread(NOENCODING_FILE))

          assert_equal(from_string.to_s.size, from_stream.to_s.size)
          assert_operator(from_string.to_s.size, :>, 0)
        end

        it "uses meta charset encoding when present" do
          html = Nokogiri::HTML4(binopen(METACHARSET_FILE))
          assert_equal("iso-2022-jp", html.encoding)
          assert_equal("たこ焼き仮面", html.title)
        end

        { "xhtml" => ENCODING_XHTML_FILE, "html" => ENCODING_HTML_FILE }.each do |flavor, file|
          it "detects #{flavor} document encoding" do
            doc_from_string_enc = Nokogiri::HTML4(binread(file), nil, "Shift_JIS")
            ary_from_string_enc = doc_from_string_enc.xpath("//p/text()").map(&:text)

            doc_from_string = Nokogiri::HTML4(binread(file))
            ary_from_string = doc_from_string.xpath("//p/text()").map(&:text)

            doc_from_file_enc = Nokogiri::HTML4(binopen(file), nil, "Shift_JIS")
            ary_from_file_enc = doc_from_file_enc.xpath("//p/text()").map(&:text)

            doc_from_file = Nokogiri::HTML4(binopen(file))
            ary_from_file = doc_from_file.xpath("//p/text()").map(&:text)

            title = "たこ焼き仮面"

            assert_equal(title, doc_from_string_enc.at("//title/text()").text)
            assert_equal(title, doc_from_string.at("//title/text()").text)
            assert_equal(title, doc_from_file_enc.at("//title/text()").text)
            assert_equal(title, doc_from_file.at("//title/text()").text)

            evil = (0..72).map { |i| "超" * i + "悪い事を構想中。" }

            assert_equal(evil, ary_from_string_enc)
            assert_equal(evil, ary_from_string)

            next unless !Nokogiri.uses_libxml? || Nokogiri::VersionInfo.instance.libxml2_has_iconv?

            # libxml2 without iconv does not pass this test
            assert_equal(evil, ary_from_file_enc)
            assert_equal(evil, ary_from_file)
          end
        end

        describe "error handling" do
          RAW = "<html><body><div></foo>"

          { "read_memory" => RAW, "read_io" => StringIO.new(RAW) }.each do |flavor, input|
            it "#{flavor} should handle errors" do
              doc = Nokogiri::HTML4.parse(input)
              assert_operator(doc.errors.length, :>, 0)
            end
          end
        end
      end
    end
  end
end
