module AsyncContent
  extend ActiveSupport::Concern

  def responds_asynchronously_with_job(job_class, *args)
    respond_to do |format|
      format.html
      format.async_content { job_class.perform_later(*args) }
    end
  end
end
