namespace :rekognition_poc do

  # rake rekognition_poc:calculate_orientation RAILS_ENV=development

  task :calculate_orientation => :environment do

    RekognitionDetectFace.find_in_batches(batch_size: 100) do |rdfs|
      rdfs.each do |rdf|

        @calculated_orientation_selfie = []
        @calculated_orientation_document = []

        image_orientation_selfie = "undefined"
        bounding_box_selfie = 0
        image_orientation_document = "undefined"
        bounding_box_document = 0

        face_details_available_selfie = 1
        face_details_available_document = 1


        if rdf.debug_data_selfie[:face_details].present? && rdf.debug_data_selfie[:face_details].length > 0
          rdf.debug_data_selfie[:face_details].each do |face|
            bounding_box = face[:bounding_box]

            orientaion_hash = {}
            dimension = (bounding_box[:width] * bounding_box[:height])
            orientaion_hash['dimension'] = dimension.to_s
            orientaion_hash['orientation'] =  calculate_orientaion(face[:landmarks])

            @calculated_orientation_selfie << orientaion_hash

            if bounding_box_selfie < dimension
              bounding_box_selfie = dimension
              image_orientation_selfie = orientaion_hash['orientation']
            end
          end
        else
          face_details_available_selfie = 0
        end

        if rdf.debug_data_document[:face_details].present? && rdf.debug_data_document[:face_details].length > 0
          rdf.debug_data_document[:face_details].each do |face|
            bounding_box = face[:bounding_box]

            orientaion_hash = {}
            dimension = (bounding_box[:width] * bounding_box[:height])
            orientaion_hash['dimension'] = dimension.to_s
            orientaion_hash['orientation'] =  calculate_orientaion(face[:landmarks])

            @calculated_orientation_document << orientaion_hash

            if bounding_box_document < dimension
              bounding_box_document = dimension
              image_orientation_document = orientaion_hash['orientation']
            end
          end
        else
          face_details_available_document = 0
        end

        puts "@calculated_orientation_selfie : #{@calculated_orientation_selfie}"
        puts "@calculated_orientation_document : #{@calculated_orientation_document}"

        puts "@image_orientation_selfie : #{image_orientation_selfie}"
        puts "@image_orientation_document : #{image_orientation_document}"

        calculated_orientation_selfie_hash = {}
        calculated_orientation_selfie_hash["data"] = @calculated_orientation_selfie

        calculated_orientation_document_hash = {}
        calculated_orientation_document_hash["data"] = @calculated_orientation_document


        rdf.calculated_orientation_selfie = calculated_orientation_selfie_hash
        rdf.calculated_orientation_document = calculated_orientation_document_hash
        rdf.image_orientation_selfie = image_orientation_selfie
        rdf.image_orientation_document = image_orientation_document
        rdf.face_details_available_selfie = face_details_available_selfie
        rdf.face_details_available_document = face_details_available_document

        rdf.save!(touch: false)
      end
    end

  end

  def calculate_orientaion(data)

     orientaion = 'undefined' #it could be stright/upward/left/right
    left_eye_x = data[0][:x]
    left_eye_y = data[0][:y]

    right_eye_x = data[1][:x]
    right_eye_y = data[1][:y]

    nose_x = data[2][:x]
    nose_y = data[2][:y]

     puts "left_eye_x : #{left_eye_x} and left_eye_y :#{left_eye_y}"
     puts "right_eye_x : #{right_eye_x} and right_eye_y : #{right_eye_y}"
     puts "nose_x : #{nose_x} and nose_y : #{nose_y}"

    if left_eye_x < nose_x && nose_x < right_eye_x && left_eye_y < nose_y
      orientaion = 'ROTATE_0'

    elsif left_eye_x > nose_x && nose_x > right_eye_x && left_eye_y > nose_y
      orientaion = 'ROTATE_180'

    elsif left_eye_y < nose_y && nose_y < right_eye_y && left_eye_x > nose_x
      orientaion = 'ROTATE_270'

    elsif left_eye_y > nose_y && nose_y > right_eye_y && left_eye_x < nose_x
      orientaion = 'ROTATE_90'
    end

     puts "orientaion : #{orientaion}"
     orientaion
  end

end
#  - :type: eyeLeft
# :x: 0.2291179746389389
# :y: 0.7144087553024292
# - :type: eyeRight
# :x: !ruby/object:BigDecimal 27:0.14964471757411957E0
# :y: 0.6976356506347656
# - :type: nose
# :x: !ruby/object:BigDecimal 27:0.18695037066936493E0
# :y: 0.6666122674942017
