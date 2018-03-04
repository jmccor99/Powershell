
Deploy Module {
    By PSGalleryModule {
        FromSource $ENV:BHProjectName
        To PSGallery
        WithOptions @{
            ApiKey = "f91c1732-fd5b-4ba8-b80d-6ffb6f7c143b"
        }
    }
}
