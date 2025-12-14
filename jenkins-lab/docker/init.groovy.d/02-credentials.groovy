import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl

def credentialsId = System.getenv("NEXUS_CREDENTIALS_ID") ?: "nexus_cred"
def username = System.getenv("NEXUS_ADMIN_USER") ?: System.getenv("JENKINS_ADMIN_USER") ?: "admin"
def password = System.getenv("NEXUS_ADMIN_PASSWORD") ?: System.getenv("JENKINS_ADMIN_PASSWORD") ?: "admin123"

def provider = SystemCredentialsProvider.getInstance()
def store = provider.getStore()
def domain = Domain.global()

def exists = store?.getCredentials(domain)?.any { it.id == credentialsId }
if (!exists) {
    def creds = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        credentialsId,
        "Auto-provisioned Nexus credentials",
        username,
        password
    )
    store.addCredentials(domain, creds)
    provider.save()
    println("[pdris] Created credentials '${credentialsId}' for user '${username}'")
} else {
    println("[pdris] Credentials '${credentialsId}' already exist")
}
