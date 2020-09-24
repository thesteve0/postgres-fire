create table plots
(
    id    serial not null
        constraint plots_pkey
            primary key,
    name  text,
    image bytea
);

CREATE OR REPLACE FUNCTION logistic_graph()
    RETURNS bytea as $$
    require(RPostgreSQL)
    # https://www.rdocumentation.org/packages/Cairo/versions/1.5-12.2/topics/Cairo
    # https://www.rdocumentation.org/packages/cairoDevice/versions/2.28.2
    # An intermediate drawing device that can output to buffer but allows normal graphing commands to work
    require(cairoDevice)

    # https://www.rdocumentation.org/packages/RGtk2/versions/2.8.7
    # Allows us to interact with the GTK buffer so we can get the bytes rather than saving to disc
    require(RGtk2)

    ########## here we read in the data and run a logistic regression model
    pg = dbDriver("PostgreSQL")
    con = dbConnect(pg, user="postgres", password="password",
                    host="localhost", port=5432, dbname="fire")

    query_statement <- paste("select hasfire, date_time, cs_precip, cs_air_max_temp,",
                                           "cs_air_min_temp, cs_soil_max_temp, cs_soil_min_temp, cs_solar, cs_eto, cs_rh_max, cs_rh_min, hasfire",
                                           "from final.analysis")
    df <- dbGetQuery(con, query_statement)

    logmodel_solar <- glm(hasfire ~ cs_rh_min + cs_air_max_temp + cs_precip + cs_solar, data=df, family = binomial("logit"))

################## Now we plot a figure from the model

    # Define the size in pixels and bits per pixel of the image we want.
    # We create a Gtk2 pixmap with these parameter
    # In this case we are making a 500 pixel x 500 pixel image with 24 bits per pixel
    # https://www.rdocumentation.org/packages/RGtk2/versions/2.8.5/topics/gdkPixmapNew
    # https://developer.gnome.org/pygtk/stable/class-gdkpixmap.html
    pixmap <- gdkPixmapNew(w=500, h=500, depth=24)

    # Now we convert the pixmap to a Cairo graphics device. After that we can use the
    # Cairo device like any normal R graphic device (i.e. R plot commands draw to it)
    # Cairo https://www.rdocumentation.org/packages/Cairo/versions/1.5-12.2/topics/Cairo
    # https://www.rdocumentation.org/packages/cairoDevice/versions/2.28.2/topics/asCairoDevice
    asCairoDevice(pixmap)

    #Normal plot command
    plot(logmodel_solar)

    # Convert out image of the plot to an RGB(A) representation in another buffer
    # Since we want to go to a buffer the first parameter, dest, is null
    # Next we give pixmap as the source and then we pass in the colormap from pixmap
    # The first two 0s setting the origin of the image
    # The next two are set to 0 because our destination is null
    # The next two parameters are the width and height respectively to get from the image
    # So if we wanted to subset our plot we could set different origin coordinates and smaller dimensions to get
    # RGB(A) https://en.wikipedia.org/wiki/RGBA_color_model
    # https://www.rdocumentation.org/packages/RGtk2/versions/2.20.31/topics/gdkPixbufGetFromDrawable
    plot_pixbuf <- gdkPixbufGetFromDrawable(NULL, pixmap,pixmap$getColormap(),0, 0, 0, 0, 500, 500)

    # Now we convert plot_pixbuf above to a binary object that is in the format of the image we want.
    # first we pass in the PixBuffer from above, then we choose our conversion format
    # Values for the format are currently "jpeg", "tiff", "png", "ico" or "bmp"
    # For statistical graphs you should try to use a lossless format such as tiff or png
    # The next two parameters set the option_keys and option_values respectively.
    # We are not setting any so we just pass in a 0 length character vector.
    # The $buffer on the end tells R we want the buffer attribute from the converted object
    # https://developer.gnome.org/gdk-pixbuf/stable/gdk-pixbuf-File-saving.html
    # https://www.rdocumentation.org/packages/RGtk2/versions/2.20.31/topics/gdkPixbufSaveToBufferv
    buffer <- gdkPixbufSaveToBufferv(plot_pixbuf, "png",character(0),character(0))$buffer

    # Now we return out buffer
    return(buffer)

$$ LANGUAGE 'plr';

insert into plots(name, image)  select 'mypicture', get_image.* from plr_get_raw(logistic_graph()) as get_image;