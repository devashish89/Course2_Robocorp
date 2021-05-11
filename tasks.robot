*** Settings ***
Documentation   Order Robots
Library    RPA.Browser
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.FileSystem
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Robocloud.Secrets
Library    RPA.Dialogs
Library    deleteOutput.py


# +
*** Keywords ***
remove output directory
    Delete Output Dir 
    
open website
    Open Available Browser  https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window

accept terms pop up
    Click Button  //button[contains(text(),'OK')]
    
get orders file from user
    Create Form    Upload CSV File
    Add File Input    label=Upload CSV file with Robot Data
    ...    name=fileupload
    ...    element_id=fileupload
    ...    filetypes=text/csv
    ...    target_directory=${CURDIR}
    &{response}    Request Response
    [Return]    ${response["fileupload"][0]}

    
get orders file
    ${status}=    Run Keyword And Return Status  get orders file from user
    LOG  ${status}
    IF    ${status} == False
        Download    https://robotsparebinindustries.com/orders.csv  target_file=orders.csv  overwrite=True
    END
    
    
create user directory
    [Arguments]  ${name}
    Create Directory  ${name}  exist_ok=True
    
take screenshot of robot
    [Arguments]  ${orderNum}
    Screenshot    //div[@id='robot-preview-image']    filename=output${/}${orderNum}${/}images${/}robot.jpg
    
create receipt PDF file
    [Arguments]  ${orderNum}
    ${content}=    Get Element Attribute    //div[@id='receipt']    innerHTML
    LOG  ${content}
    Html To Pdf    ${content}    output${/}${orderNum}${/}receipt1.PDF

    ${files}=    Create List
    ...    ${CURDIR}${/}output${/}${orderNum}${/}receipt1.PDF
    ...    ${CURDIR}${/}output${/}${orderNum}${/}images${/}robot.jpg
    
    #Add Files To PDF    ${files}    newdoc.pdf
    Add Files To Pdf  ${files}  ${CURDIR}${/}output${/}${orderNum}${/}receipt.PDF  append=True

order successful
    Click Button    id=order
    # Use the Wait Until Keyword Succeeds 3 times and at half-second intervals
    #Wait Until Keyword Succeeds    3x    0.5 sec    Your Keyword That You Want To Retry
    Page Should Contain  Receipt

zip folder
    [Arguments]  ${folderpath}
    Archive Folder With Zip  ${folderpath}  ${folderpath}.zip

fill form
    [Arguments]  ${orderNum}  ${head}  ${body}  ${legs}  ${address}
    create user directory    output${/}${orderNum}
    create user directory    output${/}${orderNum}${/}images
    Select From List By Value  head  ${head}
    Select Radio Button    body    ${body}
    Input Text    css=input[placeholder*='legs']    ${legs}
    Input Text    id=address    ${address}
    Click Button    id=preview
    Sleep    2 s
    take screenshot of robot  ${orderNum}
    Sleep  2 s
    #Click Button    id=order
    Wait Until Keyword Succeeds    3x    2 s    order successful
    create receipt PDF file  ${orderNum}
    Sleep    2 s
    zip folder  output${/}${orderNum}
    Click Button    id=order-another
    accept terms pop up
    
    
read order file
    ${table1}=    Read Table From Csv    orders.csv
    LOG  ${table1.columns}
    FOR    ${row}    IN    @{table1}
        Log    ${row}[Order number]
        Run Keyword And Continue On Failure  fill form    ${row}[Order number]    ${row}[Head]    ${row}[Body]    ${row}[Legs]    ${row}[Address]
    END
    
getting credentials
    ${secret}=    Get Secret    DummyCredentials
    
    Log    ${secret}[username]
    Log    ${secret}[password]
    
exit
    Close Browser
# -

*** Tasks ***
Order Robots from website
    remove output directory
    open website
    accept terms pop up
    create user directory    output
    get orders file
    read order file
    exit
    getting credentials

