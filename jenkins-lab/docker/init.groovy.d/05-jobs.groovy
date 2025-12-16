import hudson.model.JDK
import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition
import org.jenkinsci.plugins.workflow.job.WorkflowJob

def jenkins = Jenkins.get()

def ensureJdk = { String name, String home ->
    def desc = jenkins.getDescriptorByType(hudson.model.JDK.DescriptorImpl)
    def current = desc.getInstallations() as List<JDK>
    def exists = current.find { it.name == name }
    if (exists != null && exists.home == home) {
        return
    }

    def updated = (current.findAll { it.name != name } + [new JDK(name, home)]).toArray(new JDK[0])
    desc.setInstallations(updated)
    desc.save()
}

def ensurePipelineJob = { String jobName, File jenkinsfile ->
    if (!jenkinsfile.exists()) {
        println("[pdris] Jenkinsfile not found: ${jenkinsfile}")
        return
    }
    def script = jenkinsfile.getText("UTF-8")

    def item = jenkins.getItem(jobName)
    WorkflowJob job
    if (item == null) {
        job = jenkins.createProject(WorkflowJob, jobName)
    } else if (item instanceof WorkflowJob) {
        job = item as WorkflowJob
    } else {
        item.delete()
        job = jenkins.createProject(WorkflowJob, jobName)
    }

    job.setDefinition(new CpsFlowDefinition(script, true))
    job.save()
}

def javaHome = System.getenv("JAVA_HOME") ?: "/opt/java/openjdk"
ensureJdk("jdk17", javaHome)

def pipelinesDir = new File(jenkins.getRootDir(), "pipelines")
ensurePipelineJob("pdris-build", new File(pipelinesDir, "pdris-build.Jenkinsfile"))
ensurePipelineJob("pdris-deploy", new File(pipelinesDir, "pdris-deploy.Jenkinsfile"))
