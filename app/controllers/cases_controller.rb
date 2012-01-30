class CasesController < ApplicationController
  
  before_filter :authenticate_user!
  
  def new
    @case = Case.new
  end
  
  def create
    
    @case = Case.new(params[:case])
    @case.user = current_user
    respond_to do |format|
      if (@case.save) 
        format.html { redirect_to(cases_path, :notice => 'Case has been successfully created') }
      else  
        format.html { render :action => 'new' }
      end
    end        
    
  end
  
  def show    
    @case = resolve_case_from_id
    respond_to do |format|
      format.html { render :action => 'show' }
      format.pdf { render_pdf2(@case) }
      format.js { render :json => @case }
    end
  end
  
  def update
    @case = resolve_case_from_id
    if @case
      respond_to do |format|
        if @case.update_attributes(params[:case])
          format.html { redirect_to(@case, :notice => 'Case has been successfully updated') }
        else
          format.html { render :action => 'edit' }
        end
      end
    end
  end
  
  def destroy
    @case = resolve_case_from_id
    @case.destroy
    
    respond_to do |format|
      format.html { redirect_to(cases_path, :notice => 'The case was successfully deleted') }
    end
    
  end
  
  def edit
    @case = resolve_case_from_id
  end
  
  def index
    @cases = current_user.cases
  end
  
  private
  
  def resolve_case_from_id
    the_case = current_user.cases.find_by_id(params[:id])
    the_case ? the_case : redirect_to(cases_path)
  end
  
  def render_pdf2(the_case)
    
    report = Report.new
    report.title = the_case.title    
    report.case = the_case
    report.output_file = "report1.pdf"
    report.template = 'template.xhtml'
    
    #logger.debug(report.to_json)
    
    path = report.write_json
    command = "cd script && java -jar ReportGen.jar " + path + ""
    logger.debug(command)
    result = `#{command}`
    logger.debug(result)
    
    #File.unlink(path) if File.exists?(path)    
    
    title = the_case.title.gsub(/\s+/, '-') + '.pdf'    
    send_pdf_headers(title)
    
    send_file(report.reports_output_path,
              :filename => title, :type => 'application/pdf')

  end
  
  def send_pdf_headers(title)
    
    title = title.gsub(/\s+/, '-') + '.pdf'    
    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma'] = 'public'
      headers["Content-type"] = "application/pdf" 
      headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition'] = "attachment; filename=\"#{title}\"" 
      headers['Expires'] = "0" 
    else
      headers["Content-Type"] ||= 'application/pdf'
      headers["Content-Disposition"] = "attachment; filename=\"#{title}\"" 
    end
  end
  
  def render_pdf(the_case)
    title = the_case.title.gsub(/\s+/, '-') + '.pdf'    
    send_pdf_headers(title)
    
    send_file("#{Rails.root}/files/report1.pdf", 
              :filename => title, :type => 'application/pdf')        
    
  end

end
