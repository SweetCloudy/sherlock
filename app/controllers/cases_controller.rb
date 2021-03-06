class CasesController < ApplicationController
  
  before_filter :authenticate_user!
  
  before_filter :authorize_pi!, :except => [ :index, :preview, :show ]
  before_filter :authorize_case_create!, :only => [:new, :create]
  before_filter :resolve_case, :except => [ :new, :create, :index ]
  before_filter :verify_case_author!, :only => [ :edit, :update, :destroy ]
    
  def new
    @text_snippets = current_company.text_snippets
    @case = Case.new    
  end
  
  def create
    
    @text_snippets = current_company.text_snippets
    
    static_file = params[:upload] ? params[:upload]['static_file'] : nil    
    
    @case = Case.new(params[:case])
    @case.author = current_company    
    @case.document = Document.new(
      :title          => 'Static file', 
      :uploaded_file  => static_file
    ) if (static_file && @case.is_static)
    
    respond_to do |format|
      if (@case.save)        
        format.html { redirect_to(cases_path, :notice => 'Case has been successfully created') }
      else
        format.html { render :action => 'new' }
      end
    end        
    
  end
  
  def autosave
    
  end
  
  def preview    
    if @case.is_static
      redirect_to @case
    else  
      @letterhead = @case.author.letterhead    
      render :preview, :layout => false
    end
  end
  
  def show    
    
    @notes = @case.notes.order('id DESC').limit(5)
    
    @text_snippets = current_company.text_snippets
    
    respond_to do |format|
      #format.xml { render :xml => @case }
      format.html {
        redirect_to :action => :preview unless current_company.pi?
      }     
      format.pdf { render_pdf2(@case) }
      format.js { render :json => @case }
    end
  end
  
  def update
    
    if @case      
      
      params[:case] = convert_dates(params[:case])
      params[:case] = preparse_hinted(params[:case], params[:hinted]) if params[:hinted]
      
      @text_snippets = current_company.text_snippets
            
      respond_to do |format|
        if @case.update_attributes(params[:case])
          format.html { redirect_to(@case, :notice => 'Case has been successfully updated') }
          format.js
        else
          foreat.html { render :action => 'edit' }
          format.js
        end
      end
    end
  end
  
  def destroy
    
    @case.destroy    
    respond_to do |format|
      format.html { redirect_to(cases_path, :notice => 'The case was successfully deleted') }
    end
    
  end
  
  def edit
    @text_snippets = current_company.text_snippets
  end
  
  def index
    
    @folders = current_company.folders    
    @cases =  cases_for_user
    
  end
  
  private
    
  def cases_for_user
    if current_company.pi?
      current_company.cases.select { |c| c.folder_id == nil }
    else
      current_company.cases
    end
  end
  
  def verify_case_author!    
    is_author = (@case.author == current_company)
    redirect_to @case unless is_author    
  end
  
  def resolve_case
    resolve_case_using_param(:id)
  end
  
  def render_pdf2(the_case)
    
    report = Report.new
    report.title = the_case.title
    report.header = current_company.letterhead
    report.case = the_case    
    report.template = 'template.xhtml'        
    
    report.generate_pdf        
    
    title = the_case.title.strip.gsub(/\s+/, '-') + '.pdf'
    title = title.gsub('"', '')
    send_pdf_headers(title)
    
    send_file(report.reports_output_path,
              :filename => title, :type => 'application/pdf')

  end
  
  def send_pdf_headers(title)
    
    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      headers['Pragma']               = 'public'
      headers["Content-type"]         = "application/pdf" 
      headers['Cache-Control']        = 'no-cache, must-revalidate, post-check=0, pre-check=0'
      headers['Content-Disposition']  = "attachment; filename=\"#{title}\"" 
      headers['Expires']              = "0" 
    else
      headers["Content-Type"] ||= 'application/pdf'
      headers["Content-Disposition"]  = "attachment; filename=\"#{title}\"" 
    end
  end
  
  def render_pdf(the_case)
    title = the_case.title.gsub(/\s+/, '-') + '.pdf'    
    send_pdf_headers(title)
    
    send_file("#{Rails.root}/files/report1.pdf", 
              :filename => title, :type => 'application/pdf')        
    
  end
  
  def preparse_hinted(params, hinted)    
    hinted.to_a.each do |key, value|      
      params[key.to_sym] = '' if value.to_i == 1      
    end        
    params    
  end
  
  def convert_date(date_string)
    if date_string.to_s =~ /(\d\d)\/(\d\d)\/(\d{4})/
      date_string = "#{$3}-#{$1}-#{$2}"
    end
    date_string
  end
  
  def upgrade_or_purchase
    
    @current_user = current_company
    @plans        = current_company.plans_to_upgrade
    @current_plan = current_company.current_plan
    
    @subscription = current_company.current_subscription
    @subscription_inactive = @subscription && @subscription.is_inactive?
    
    @subscription_expired = @subscription && @subscription.is_expired?
    
    render @current_plan ? 'upgrade_or_purchase' : 'upgrade'
  end
  
  def authorize_case_create!
    upgrade_or_purchase unless current_company.can_create_case?
  end
  
  def convert_dates(params)    
    params['opened_on']   = convert_date(params['opened_on'])
    params['closed_on']   = convert_date(params['closed_on'])
    params['report_date'] = convert_date(params['report_date'])
    params
  end
    
end
