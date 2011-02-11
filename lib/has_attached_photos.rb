module HavePhotos
  module Roled
    module Acts
      def self.included(base) 
        base.extend AddActsAsMethod
      end 
      
      module AddActsAsMethod
        def has_attached_photos
          class_eval <<-END
            include HavePhotos::Roled::Acts::Attaches
          END
        end
      end
      
      module Attaches
        def self.included(base)
          base.class_eval do
            has_many :attaches, :include => :comments
            accepts_nested_attributes_for :attaches, :allow_destroy => true, :reject_if => proc{ |att| att['photo'].blank? }
            
            def after_initialize #build new attach only for controller action :new 
              self.attaches.build if self.new_record? && self.attributes.values.find_all{|val| !val.blank?}.empty?
            end
          end
        end 
      end
    end
  end 

  module ShowPic
    module Controller
      def self.included(base) 
        base.extend AddShowMethod
      end 
      
      module AddShowMethod
        def shows_attached_photos
          class_eval <<-END
            include HavePhotos::ShowPic::Controller::ShowsPhotos
          END
        end
      end
      
      module ShowsPhotos
        def self.included(base)
          base.class_eval do
            helper_method :view_types
            
            def get_view_type
              @view_type = params[:view_type] || "filmstrip"
              @comments = Comment.find_all_by_attach_id @user.attaches[@view_type == 'gallery' ? -1 : 0].id if @user.attaches.any?
            end 
            
            def get_index_view_type
              @view_type = "thumbnails"
            end
            
            def view_types
              %w[filmstrip gallery thumbnails]
            end
          end
        end    
      end
    end
  end
  
  module PhotoViewHelper      
    def show_comments user, comments
      render :partial => "comments/show_comments", :locals => {:user => user, :comments => comments}
    end
    
    def show_photos user, view_type
      render :partial => view_type, :locals => {:photos => user.attaches} unless user.attaches.blank?
    end
    
    def view_type_select user
      render :partial => 'switch', :locals => {:user => user}
    end
    
    def new_photo form
      render :partial => 'new_photo', :locals => {:f => form}
    end
    
    def edit_photo form
      render :partial => 'edit_photo', :locals => {:f => form}
    end

    def get_js_and_styles jquery_file_name
      render :partial => 'layouts/inc', :locals => {:jquery_file_name => jquery_file_name}
    end
  end
end

