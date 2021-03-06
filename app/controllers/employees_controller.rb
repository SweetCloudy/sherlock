class EmployeesController < ApplicationController
  
  before_filter :authenticate_user!
  before_filter :authorize_pi!
  before_filter :block_employee!
  
  before_filter :resolve_employee!, :only => [ :show, :edit, :update ]
    
  def index    
    @employees = current_user.employees   
  end
  
  def new    
    @employee = current_user.employees.build
  end
  
  def create
    
    @employee = User.new params[:user]
    @employee.password_confirmation = @employee.password
    @employee.employers = [ current_user ]
    @employee.confirmed_at = Time.now
    
    if @employee.save            
      logger.info('Created the employee!')      
      redirect_to employees_path, :notice => 'Employee has been added'
    else    
      render 'new'
    end
  end
  
  def edit
    @employee.build_user_address unless @employee.user_address
  end
  
  def show
    @employee.build_user_address unless @employee.user_address  
    @cases = current_user.cases
  end
  
  def update       
    
    data = params[:user] || {}
    address = data[:user_address_attributes] || {}
    info = data[:employee_info_attributes] || {}
        
    pp 'info:'
    pp info
    
    @employee.email = data[:email]
    @employee.first_name = data[:first_name]
    @employee.last_name = data[:last_name]
    @employee.user_address || @employee.build_user_address
    
    @employee.employee_info.active = (info[:active].to_i == 1)
    
    @employee.user_address.phone = address[:phone]
    
    if data[:password].present?
      @employee.password = data[:password]
      @employee.password_confirmation = data[:password_confirmation]
      
      pp @employee
      
    end
    
         
    if @employee.save      
      redirect_to employee_path(@employee), :notice => 'Employee info has been updated'
    else
      flash[:alert] = 'Employee could not be updated'
      render 'edit'
    end
  end
  
  private
  
  def resolve_employee!
    @employee = current_user.employees.find_by_id(params[:id])
    redirect_to employees_path unless @employee
  end
  
end
