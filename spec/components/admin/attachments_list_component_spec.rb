require "rails_helper"

RSpec.describe Admin::AttachmentsListComponent, type: :component do
  def build_attachment(filename:, content_type:)
    blob = double(
      "ActiveStorage::Blob",
      signed_id: SecureRandom.base58(24),
      filename:  ActiveStorage::Filename.new(filename)
    )
    double(
      "ActiveStorage::Attachment",
      filename:     ActiveStorage::Filename.new(filename),
      content_type: content_type,
      blob:         blob
    )
  end

  let(:pdf)   { build_attachment(filename: "terms.pdf",     content_type: "application/pdf") }
  let(:word)  { build_attachment(filename: "contract.docx", content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document") }
  let(:excel) { build_attachment(filename: "data.xlsx",     content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet") }
  let(:image) { build_attachment(filename: "photo.jpg",     content_type: "image/jpeg") }
  let(:video) { build_attachment(filename: "clip.mp4",      content_type: "video/mp4") }
  let(:other) { build_attachment(filename: "archive.zip",   content_type: "application/zip") }

  describe "render?" do
    it "does not render when the attachments collection is empty" do
      render_inline described_class.new(attachments: [])
      expect(page).to have_no_css("ul")
    end

    it "renders when at least one attachment is present" do
      render_inline described_class.new(attachments: [pdf])
      expect(page).to have_css("ul")
    end
  end

  describe "filename links" do
    it "renders a row for each attachment" do
      render_inline described_class.new(attachments: [pdf, image])
      expect(page).to have_css("li", count: 2)
    end

    it "displays the filename as link text" do
      render_inline described_class.new(attachments: [pdf])
      expect(page).to have_link("terms.pdf")
    end

    it "links to the blob download path" do
      render_inline described_class.new(attachments: [pdf])
      href = page.find("a[download], a[href*='active_storage']", match: :first)["href"]
      expect(href).to include("active_storage")
    end

    it "opens downloads in a new tab" do
      render_inline described_class.new(attachments: [pdf])
      link = page.find("li a", match: :first)
      expect(link["target"]).to eq("_blank")
    end
  end

  describe "icons" do
    it "shows bi-image for images" do
      render_inline described_class.new(attachments: [image])
      expect(page).to have_css("i.bi.bi-image")
    end

    it "shows bi-camera-video for videos" do
      render_inline described_class.new(attachments: [video])
      expect(page).to have_css("i.bi.bi-camera-video")
    end

    it "shows bi-file-pdf for PDFs" do
      render_inline described_class.new(attachments: [pdf])
      expect(page).to have_css("i.bi.bi-file-pdf")
    end

    it "shows bi-file-word for Word documents" do
      render_inline described_class.new(attachments: [word])
      expect(page).to have_css("i.bi.bi-file-word")
    end

    it "shows bi-file-excel for Excel spreadsheets" do
      render_inline described_class.new(attachments: [excel])
      expect(page).to have_css("i.bi.bi-file-excel")
    end

    it "shows bi-file-earmark for unknown file types" do
      render_inline described_class.new(attachments: [other])
      expect(page).to have_css("i.bi.bi-file-earmark")
    end
  end

  describe "delete button" do
    let(:delete_path) { ->(a) { "/admin/attachments/#{a.blob.signed_id}" } }

    context "when delete_path is provided" do
      it "renders a delete link for each attachment" do
        render_inline described_class.new(attachments: [pdf, image], delete_path: delete_path)
        expect(page).to have_css("li a[data-turbo-method]", count: 2)
      end

      it "uses DELETE as the default turbo method" do
        render_inline described_class.new(attachments: [pdf], delete_path: delete_path)
        expect(page).to have_css("a[data-turbo-method='delete']")
      end

      it "uses the turbo method override when specified" do
        render_inline described_class.new(
          attachments:   [pdf],
          delete_path:   delete_path,
          delete_method: :patch
        )
        expect(page).to have_css("a[data-turbo-method='patch']")
      end

      it "includes a turbo-confirm on the delete link" do
        render_inline described_class.new(attachments: [pdf], delete_path: delete_path)
        expect(page).to have_css("a[data-turbo-confirm*='terms.pdf']")
      end

      it "points the delete link at the path returned by the lambda" do
        render_inline described_class.new(attachments: [pdf], delete_path: delete_path)
        signed_id = pdf.blob.signed_id
        expect(page).to have_css("a[href='/admin/attachments/#{signed_id}']")
      end

      it "includes an aria-label on the delete link" do
        render_inline described_class.new(attachments: [pdf], delete_path: delete_path)
        expect(page).to have_css("a[aria-label*='terms.pdf']")
      end
    end

    context "when delete_path is omitted" do
      it "renders no delete links" do
        render_inline described_class.new(attachments: [pdf, image])
        expect(page).to have_no_css("a[data-turbo-method]")
      end
    end
  end
end
