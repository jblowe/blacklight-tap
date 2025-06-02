# frozen_string_literal: true
class CatalogController < ApplicationController

  include Blacklight::Catalog

  configure_blacklight do |config|
    config.view.gallery(document_component: Blacklight::Gallery::DocumentComponent, icon: Blacklight::Gallery::Icons::GalleryComponent)
    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)

    #config.view.gallery(document_component: Blacklight::Gallery::DocumentComponent)

    # disable these three document action until we have resources to configure them to work
    config.show.document_actions.delete(:citation)
    config.show.document_actions.delete(:sms)
    config.show.document_actions.delete(:email)

    # config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)

    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)

    # config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    # config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

    # solr path which will be added to solr base url before the other solr params.
    config.solr_path = 'select'
    config.document_solr_path = 'select'

    # items to show per page, each number in the array represent another option to choose from.
    config.per_page = [80,160,240,1000]

    config.default_facet_limit = 10

    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    #
    # customizations to support existing Solr cores
    config.default_solr_params = {
        'rows': 12,
        'facet.mincount': 1,
        'q.alt': '*:*',
        'defType': 'edismax',
        'df': 'text',
        'q.op': 'AND',
        'q.fl': '*,score'
    }

    # solr path which will be added to solr base url before the other solr params.
    # config.solr_path = 'select'

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SearchHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {
        qt: 'document',
        #  ## These are hard-coded in the blacklight 'document' requestHandler
        #  # fl: '*',
        #  # rows: 1,
        # this is needed for our Solr services
        q: '{!term f=id v=$id}'
    }

    # solr field configuration for search results/index views
    # list of images is hardcoded for both index and show displays
    #{index_title}
    config.index.thumbnail_field = 'THUMBNAIL_s'

    # solr field configuration for document/show views
    #{show_title}
    config.show.thumbnail_field = 'THUMBNAIL_s'

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # use existing "catchall" field called text
    # config.add_search_field 'text', label: 'Any field'
    config.spell_max = 5

    # SEARCH FIELDS
    config.add_search_field 'text', label: 'Any field'

    [
      ['T_txt', 'T number'],
      ['KEY_txt', 'Key'],
      ['KEYTERMS_txt', 'Keyterms'],
      ['MATERIAL_txt', 'Material'],
      ['NOTES_txt', 'Notes']
      ].each do |search_field|
      config.add_search_field(search_field[0]) do |field|
        field.label = search_field[1]
        #field.solr_parameters = { :'spellcheck.dictionary' => search_field[0] }
        field.solr_parameters = {
          qf: search_field[0],
          pf: search_field[0],
          op: 'AND'
        }
      end
    end

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = false
    config.autocomplete_path = 'suggest'

    # FACET FIELDS
     config.add_facet_field 'DTYPE_s', label: 'Doc type', limit: true
     config.add_facet_field 'DTYPES_ONLY_ss', label: 'Doc Types', limit: true
     config.add_facet_field 'T_s', label: 'T', limit: true
     config.add_facet_field 'KEY_s', label: 'KEY', limit: true
     # config.add_facet_field 'T_i', label: 'T numeric', limit: true
     config.add_facet_field 'SITE_s', label: 'SITE', limit: true
     config.add_facet_field 'YEAR_s', label: 'YEAR', limit: true
     config.add_facet_field 'ROLL_s', label: 'ROLL', limit: true
     config.add_facet_field 'EXP_s', label: 'EXP', limit: true
     config.add_facet_field 'NOTES_s', label: 'NOTES', limit: true
     config.add_facet_field 'MATERIAL_s', label: 'MATERIAL', limit: true
     config.add_facet_field 'CLASS_s', label: 'CLASS', limit: true
     config.add_facet_field 'OP_s', label: 'OP', limit: true
     config.add_facet_field 'AREA_s', label: 'AREA', limit: true
     config.add_facet_field 'LEVEL_s', label: 'LEVEL', limit: true
     config.add_facet_field 'LOT_s', label: 'LOT', limit: true
     config.add_facet_field 'BURIAL_s', label: 'BURIAL', limit: true
     config.add_facet_field 'DATE_s', label: 'DATE', limit: true
     config.add_facet_field 'REVISIOND_s', label: 'REVISIOND', limit: true
     config.add_facet_field 'DUPLICATED_s', label: 'DUPLICATED', limit: true
     config.add_facet_field 'EXCAVATOR_s', label: 'EXCAVATOR', limit: true
     config.add_facet_field 'FEA_s', label: 'FEA', limit: true
     config.add_facet_field 'NOTES2_s', label: 'NOTES2', limit: true
     config.add_facet_field 'OBJ_s', label: 'OBJ', limit: true
     config.add_facet_field 'PHOTOTYPE_s', label: 'PHOTOTYPE', limit: true
     config.add_facet_field 'REG_s', label: 'REG', limit: true
     config.add_facet_field 'KEYTERMS_ss', label: 'KEYTERMS', limit: true

    # INDEX DISPLAY
     config.add_index_field 'T_s', label: 'T'
     config.add_index_field 'KEY_s', label: 'KEY'
     # config.add_index_field 'T_i', label: 'T (numeric)'
     # config.add_index_field 'TITLE_s', label: 'TITLE'
     config.add_index_field 'SITE_s', label: 'SITE'
     config.add_index_field 'YEAR_s', label: 'YEAR'
     config.add_index_field 'ROLL_s', label: 'ROLL'
     config.add_index_field 'EXP_s', label: 'EXP'
     config.add_index_field 'OP_s', label: 'OP'
     config.add_index_field 'SQ_s', label: 'SQ'
     config.add_index_field 'LEVEL_s', label: 'LEVEL'
     config.add_index_field 'AREA_s', label: 'AREA'
     config.add_index_field 'LOT_s', label: 'LOT'
     config.add_index_field 'FEA_s', label: 'FEA'
     config.add_index_field 'OBJ_s', label: 'OBJ'
     config.add_index_field 'NOTES_s', label: 'NOTES'
     config.add_index_field 'MATERIAL_s', label: 'MATERIAL'
     config.add_index_field 'DATE_s', label: 'DATE'

     config.add_index_field 'REVISIOND_s', label: 'REVISIOND'
     config.add_index_field 'DUPLICATED_s', label: 'DUPLICATED'
     config.add_index_field 'EXCAVATOR_s', label: 'EXCAVATOR'
     config.add_index_field 'NOTES2_s', label: 'NOTES2'
     config.add_index_field 'TRAY_s', label: 'TRAY'
     config.add_index_field 'DTYPES_ss', label: 'Doc types'
     config.add_index_field 'RECORDS_ss', helper_method: 'render_records', label: 'Records'
     config.add_index_field 'IMAGES_ss', helper_method: 'render_images', label: 'Images'
     config.add_index_field 'FILENAMES_ss', helper_method: 'render_filenames', label: 'Filenames'
     # config.add_index_field 'PHOTOTYPE_s', label: 'PHOTOTYPE'
     # config.add_index_field 'REG_s', label: 'REG'
     config.add_index_field 'KEYTERMS_s', label: 'KEYTERMS'
     config.add_index_field 'FILEPATH_s', helper_method: 'render_image_link', label: 'MEDIA'
     config.add_index_field 'FILENAME_s', label: 'FILENAME'
     # config.add_index_field 'THUMBNAILNAME_s', label: 'THUMB'
     config.add_index_field 'DTYPE_s', label: 'DTYPE'


    # SHOW DISPLAY
     config.add_show_field 'T_s', label: 'T'
     config.add_show_field 'KEY_s', label: 'KEY'
     # config.add_show_field 'T_i', label: 'T (numeric)'
     config.add_show_field 'SITE_s', label: 'SITE'
     config.add_show_field 'YEAR_s', label: 'YEAR'
     config.add_show_field 'ROLL_s', label: 'ROLL'
     config.add_show_field 'EXP_s', label: 'EXP'
     config.add_show_field 'OP_s', label: 'OP'
     config.add_show_field 'SQ_s', label: 'SQ'
     config.add_show_field 'LOT_s', label: 'LOT'
     config.add_show_field 'AREA_s', label: 'AREA'
     config.add_show_field 'LEVEL_s', label: 'LEVEL'
     config.add_show_field 'DATE_s', label: 'DATE'
     config.add_show_field 'REVISIOND_s', label: 'REVISIOND'
     config.add_show_field 'NOTES_s', label: 'NOTES'
     config.add_show_field 'DUPLICATED_s', label: 'DUPLICATED'
     config.add_show_field 'EXCAVATOR_s', label: 'EXCAVATOR'
     config.add_show_field 'FEA_s', label: 'FEA'
     config.add_show_field 'FEATURE__s', label: 'FEATURE_'
     config.add_show_field 'NOTES2_s', label: 'NOTES2'
     config.add_show_field 'OBJ_s', label: 'OBJ'
     config.add_show_field 'WEIGHT_s', label: 'WEIGHT'
     config.add_show_field 'PHOTOTYPE_s', label: 'PHOTOTYPE'
     config.add_show_field 'REG_s', label: 'REG'
     config.add_show_field 'DTYPE_s', label: 'DTYPE'
     config.add_show_field 'BURIAL_s', label: 'BURIAL'
     config.add_show_field 'B_s', label: 'B'
     config.add_show_field 'CLASS_s', label: 'CLASS'
     config.add_show_field 'COUNT_s', label: 'COUNT'
     config.add_show_field '# DIRECTORY_s', label: '# DIRECTORY'
     config.add_show_field 'ENTRY_DATE_s', label: 'ENTRY_DATE'
     config.add_show_field 'EXCAVATIONDATE_s', label: 'EXCAVATIONDATE'
     config.add_show_field 'MATERIAL_s', label: 'MATERIAL'
     config.add_show_field 'REGISTRAR_s', label: 'REGISTRAR'
     config.add_show_field 'UNKNOWN_s', label: 'UNKNOWN'
     config.add_show_field 'ETC_s', label: 'ETC'
     config.add_show_field 'TRAY_s', label: 'TRAY'
     config.add_show_field 'FILENAME_s', label: 'FILEPATH'
     config.add_show_field 'IMAGENAME_s', label: 'FILENAME'
     config.add_show_field 'KEYTERMS_s', label: 'KEYTERMS'
     config.add_show_field 'RECORDS_ss', helper_method: 'render_records', label: 'RECORDS'
     config.add_show_field 'IMAGES_ss', helper_method: 'render_images', label: 'Images'
     #config.add_show_field 'FILENAMES_ss', helper_method: 'render_filenames', label: 'Filenames'


    # SORT FIELDS
    config.add_sort_field 'SITE_s asc, YEAR_s asc, ROLL_s asc, EXP_s asc', label: 'Site, Season, R, E'
    config.add_sort_field 'T_i asc, SITE_s asc, YEAR_s asc, ROLL_s asc, EXP_s asc', label: 'T number'
    config.add_sort_field 'KEY_s asc, T_s asc, SITE_s asc', label: 'Key, then T#'
    config.add_sort_field 'FILENAME_s asc, T_s asc, SITE_s asc, YEAR_s asc, ROLL_s asc, EXP_s asc', label: 'Images, then T#'

    # TITLE
    config.index.title_field = 'TITLE_s'
    config.show.title_field = 'TITLE_s'

  end
end
