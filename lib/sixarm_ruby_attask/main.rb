#!/usr/bin/ruby

=begin

For example, if you are a hosted client with a
domain name of abc.attask-ondemand.com, then your URL would look like the following:
https://abc.attask-ondemand.com/attask/viewWSDL

=end


# Comment this line out when running in production.
ini_set("soap.wsdl_cache_enabled","0");

# Please change this line to refer to the IP address or hostname of @task.
attask_host = 'localhost';
wsdl_url = "http://$attask_host:8080/attaskWS/API?wsdl";
#wsdl_url = "https://$attask_host:8443/attaskWS/API?wsdl";

username = 'admin';
password = 'user';


INT_NULL = ?

begin

  # The SoapClient class cannot read from a string, so we need to create a file.
  myFile = 'API.wsdl';
  fh = fopen(myFile, 'w') or die('Cannot open file');
  fwrite(fh, dom.saveXML());
  fclose(fh);

  # Connect to server.
  opts = array('features' => SOAP_SINGLE_ELEMENT_ARRAYS, 'trace' => 1);
  api = new SoapClient(myFile, opts); # $wsdl is defined in WSDLParser.php.
  #var_dump(api.__getFunctions());
  #var_dump(api.__getTypes());

  # Login.
  puts "Logging in to web service";
  session_id = api.login(username, password);

  # NOTE: If the following line causes a SoapFault please see the notes at the top of this file.
  session_attributes = api.getSessionAttributes(session_id);
  session_attributes.intNull;

  # Find a group for the new project.
  puts "Searching for groups"; 
  groups = api.getGroups(session_id).value;
  group_id = groups[0].ID; # There is a default group that includes everybody.

  # Create a project.
  project = Project.new
  project.name = 'Project Name';
  project.groupID = group_id;

  # All of these fields must be set to some value, but NULL is OK.
  project.categoryID = int_null;
  project.scheduleID = int_null;
  project.templateID = int_null;
  
  # The planned start date is required.
  project.plannedStartDate = date('c');

  # These fields are not required, but must use one of the values listed in the provided documentation.
  project.status = 'CUR';
  project.completionType = 'MAN';
  project.updateType = 'AUTO';

  puts "Creating a project";
  project_id = api.addProject(session_id, project);

  # Add a document to the project.
  document = Document.new
  document.name = 'hello.txt';

  # All of these fields must be set to some value, but NULL is OK.
  document.categoryID = int_null;
  
  # Set the document version.
  documentVersion = DocumentVersion.new
  documentVersion.version = 'Version 1';
  document.currentVersion = documentVersion;

  # Create the document and store its ID.
  puts "Creating a document\n";
  contents = 'Hello World';
  document_id = api.uploadProjectDocument(session_id, project_id, document, contents);

  # Update the contents of the document.
  document.ID = document_id;
  documentVersion.version = 'Version 2';
  contents[6] = 'H';
  puts "Uploading a new version of the document";
  document_id1 = api.uploadProjectDocument(session_id, project_id, document, contents);

  # Download document contents.
  puts "Downloading the document\n";
  contentsCheck = api.downloadDocument(session_id, document_id);

  # Add a task to the project.
  task1 = Task.new
  task1.name = 'Task Name';
  task1.projectID = project_id;

  # By default, the duration is stored in 8 hour days.
  task1.duration = 3.0;
  task1.percentComplete = 0.0;

  # This field is also required and must use one of the values listed in the provided Javadoc documentation.
  task1.priority = 1;

  # These are required fields, but NULL or empty values are OK.
  task1.roleID = int_null;
  task1.categoryID = int_null;
  task1.milestoneID = int_null;
  task1.assignedToID = int_null;
  task1.parentID = int_null;

  # Create the task and store its ID.
  puts "Creating a task";
  task_ids = api.addTasks(session_id, array(task1)).value;

  # Edit the task.
  task2 = api.getTaskByTaskID(session_id, task_ids[0]);
  task2.name = 'New Task Name';
  puts "Editing a task";
  api.editTask(session_id, task2);

  task3 = api.getTaskByTaskID(session_id, task_ids[0]);
  if (task3.name != 'New Task Name') 
    puts "***** Task not modified *****\n";
  end

  # Create an issue category.
  category = Category.new
  category.name = 'Category Name';
  category.groupID = group_id;

  # These are required fields, but NULL or empty values are OK.
  category.description = 'This is a category description';
  category.parameterIDs = array();

  # This field is also required and must use one of the values listed in the provided Javadoc documentation.
  category.catObjCode = 'OPTASK';

  # Create the category and store its ID.
  puts "Creating an issue category";
  category_id = api.addCategory(session_id, category);

  # Create a categoriezed issue.
  issue1 = new Issue.new
  issue1.name = 'Issue Name';
  issue1.projectID = project_id;
  issue1.categoryID = category_id;

  # These are required fields, but NULL or empty values are OK.
  issue1.queueTopicID = int_null;
  issue1.roleID = int_null;
  issue1.ownerID = int_null;
  issue1.assignedToID = int_null;

  # This field is also required and must use one of the values listed in the provided Javadoc documentation.
  issue1.opTaskType = 'ISU';

  # This field is not required, but must use one of the values listed in the provided Javadoc documentation.
  issue1.priority = 1;

  puts "Creating a categorized issue";
  issue_id = api.addOpTask(session_id, issue1);

  # Edit the issue.
  issue2 = api.getOpTaskByOptaskID(session_id, issue_id);
  issue2.name = 'New Issue Name';
  puts "Editing an issue";
  api.editOpTask(session_id, issue2);

  issue3 = api.getOpTaskByOptaskID(session_id, issue_id);
  if (issue3.name != 'New Issue Name') 
      puts "***** Issue not modified *****\n";
  end

rescue => err
  puts "***** Failure *****";
  puts err
end

if api && session_id
  begin
    puts "Cleaning up";
    if issue_id && issue_id != int_null && issue_id != 0
      deleted_issue = api.deleteOpTask(session_id, issue_id)
    end
    if category_id && category_id != int_null && category_id != 0
      deleted_category = api.deleteCategory(session_id, category_id)
    end
    if task_ids && task_ids != null && count(task_ids) > 0
      deleted_tasks = api.deleteTasks(session_id, task_ids)
    end
    if document_id && document_id != int_null && document_id != 0
      deleted_document = api.deleteDocument(session_id, document_id)
    end
    if project_id && project_id != int_null && project_id != 0
      deleted_project = api.deleteProject(session_id, project_id)
    end
    # Logout
    api.logout(session_id);
  rescue => err
    puts err
  end
end

puts "Finished"

