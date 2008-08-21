class FamiliesController < ApplicationController
  
  cache_sweeper :person_sweeper, :family_sweeper, :only => %w(create update destroy)
  
  def index
    respond_to do |format|
      format.html { redirect_to @logged_in }
      if can_export?
        @families = Family.paginate(:order => 'last_name, name, suffix', :page => params[:page], :per_page => params[:per_page] || 50)
        format.xml { render :xml  => @families.to_xml(:include => [:people]) }
        format.csv { render :text => @families.to_csv }
      end
    end
  end
  
  def show
    @family = Family.find(params[:id])
    @people = @family.people.all.select { |p| @logged_in.can_see? p }
    if @logged_in.can_see?(@family)
      respond_to do |format|
        format.html
        format.xml { render :xml => @family.to_xml } if can_export?
      end
    else
      render :text => 'Family not found.', :status => 404
    end
  end
  
  before_filter :can_edit?, :only => %w(new create edit update destroy reorder)
  
  def new
    @family = Family.new
  end
  
  def create
    @family = Family.create(params[:family])
    redirect_to @family
  end
  
  def edit
    @family = Family.find(params[:id])
  end

  def update
    @family = Family.find(params[:id])
    @family.update_attributes(params[:family])
    respond_to do |format|
      format.html { redirect_to @family }
      format.xml  { render :xml => @family.to_xml } if can_export?
    end
  end
  
  def destroy
    @family = Family.find(params[:id])
    if @family == @logged_in.family
      flash[:warning] = 'You cannot delete your own family.'
      redirect_to @family
    else
      @family.destroy
      redirect_to people_path
    end
  end
  
  def reorder
    @family = Family.find(params[:id])
    params[:people].to_a.each_with_index do |id, index|
      @family.people.find_by_id(id).update_attribute(:sequence, index+1)
    end
    render :nothing => true
  end
  
  private

  def can_edit?
    unless @logged_in.admin?(:edit_profiles)
      render :text => 'Not authorized or feature unavailable.', :layout => true, :status => 401
      return false
    end
  end
end
