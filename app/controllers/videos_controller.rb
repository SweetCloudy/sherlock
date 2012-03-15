class VideosController < ApplicationController
  
  before_filter :authenticate_user!
  before_filter :authorize_pi!
  
  #
  # Note: we may want to remove it, if this controller will also be
  #       used to upload videos unlinked with any blocks/cases
  #
  before_filter :resolve_case, :only => [ :new, :edit, :show, :update, :create ]
  
  def new
    
    block = Block.new
    block.case = @case    
    @video  = Video.generate(block)            
    @insert_before_id = params[:insert_before_id].to_i    
    @cookie = cookies['_sherlock_session']
  end
  
  def create
    
    
    params[:upload] ||= {}
    
    if params[:video][:thumbnail_method] == 'auto'
      params[:upload].delete('thumbnail')
    end    
    params[:video].delete(:thumbnail_method)
       
    video     = params[:upload]['video']
    thumbnail = params[:upload]['thumbnail']
            
    if video
    
      params[:video][:original_filename] = video.original_filename
      params[:video][:content_type]      = video.content_type    

      logger.debug("create: storing the video - #{Time.now.to_i}")
      video_filename = Video.store(current_user, video)
      
      start_time = params[:start_time].to_i
      end_time   = params[:end_time].to_i
      
      if video_filename.end_with?('zip')
        logger.debug("create: encoding the video - #{Time.now.to_i}")
        encoding_info = Video.encode(
          current_user.id, video_filename, start_time, end_time)
        video_filename = encoding_info.filename
        params[:video][:content_type] = encoding_info.content_type
        params[:video][:fps] = encoding_info.fps
        params[:video][:duration] = encoding_info.duration      
        logger.debug("create: encoding done - #{Time.now.to_i}")
      end
              
      params[:video][:path] = video_filename

      # store thumbnail or automatically generate a new one:
      thumbnail_info = {}

      logger.debug('Thumbnail is:')
      logger.debug(thumbnail)

      if thumbnail
        thumbnail_info = 
          Video.store_thumbnail(current_user.id, video_filename, thumbnail)
        params[:video].delete(:thumbnail_pos)
      else
        thumbnail_info =
          Video.extract_thumbnail_from_movie(current_user.id, video_filename, 
                                             params[:video][:thumbnail_pos])
      end    

      params[:video][:thumbnail]  = thumbnail_info[:filename]    
      params[:video][:width]      = thumbnail_info[:width]
      params[:video][:height]     = thumbnail_info[:height]
        
    end
      
    @video = Video.new(params[:video])
    block = Block.new(:case => @case)
    @insert_before_id = params[:insert_before_id].to_i
    block.insert_before_id = @insert_before_id    
    @video.block = block
    logger.debug("Recoding to FLV")    
    
    respond_to do |format|
      if (@video.save) 
        @video.recode_to_formats
        format.html { redirect_to(@case, :notice => 'Video block has been added') }
      else  
        format.html { render :action => 'new' }
      end
    end        
    
  end
  
  def show
    @video = @case.videos.find_by_unique_code(params[:id])
    respond_to do |format|
      format.js { render :json => @video }
    end
  end
  
  def edit
    @insert_before_id = 0
    @video = @case.videos.find_by_id(params[:id])        
    @cookie = cookies['_sherlock_session']
    redirect_to cases_path unless @video    
  end
  
  def update
    
    @video = @case.videos.find_by_id(params[:id])    
    redirect_to cases_path unless @video
    
    thumbnail_method = params[:video][:thumbnail_method]
    
    if params[:upload] && (params[:video][:thumbnail_method] == 'auto')
      params[:upload].delete('thumbnail')
    end    
    params[:video].delete(:thumbnail_method)    
    
    respond_to do |format|
      if @video.update_attributes(params[:video])
        video = params[:upload] ? params[:upload]['video'] : nil
        if video
          
          start_time = params[:start_time].to_i
          end_time   = params[:end_time].to_i
                
          video_filename = Video.store(current_user, video)
          
          if video_filename.end_with?('zip')
            encoding_info = Video.encode(
              current_user.id, video_filename, start_time, end_time)
            video_filename = encoding_info.filename
            video.content_type = encoding_info.content_type
            video.fps = encoding_info.fps      
            video.duration = encoding_info.duration
          end
                    
          @video.delete_file
          @video.path = video_filename
          @video.rename_thumbnail if @video.thumbnail
          @video.recode_to_formats
          @video.save
        end
        
        unless params[:keep_thumbnail].to_i == 1
          
          case thumbnail_method
          when 'auto'
            logger.debug('Extracting the thumbnail automatically!')
            Video.extract_thumbnail_from_movie(current_user.id, @video.path, 
                                               @video.thumbnail_pos)
          when 'manual'
            if params[:upload] && params[:upload]['thumbnail']
              logger.debug('Updating the thumbnail manually!')
              thumbnail = params[:upload]['thumbnail']
              thumbnail_info = 
                Video.store_thumbnail(current_user.id, @video.path, thumbnail)              
              @video.thumbnail_pos  = nil
              @video.width          = thumbnail_info[:width]
              @video.height         = thumbnail_info[:height]
              @video.save
            end
          end
          
        else
          logger.debug("Keeping the thumbnail!!!!")
        end
        
        format.html { redirect_to(@case, :notice => 'The block has been successfully updated') }
      else
        format.html { render :action => 'edit' }
      end
    end
    
  end
  
  private
  
  def resolve_case
    resolve_case_using_param(:case_id)    
  end
  
end
