import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl

def provider = SystemCredentialsProvider.getInstance()
def store = provider.getStore()
def domain = Domain.global()

def credentialsToEnsure = [
    [
        id: System.getenv("NEXUS_CREDENTIALS_ID") ?: "nexus_cred",
        username: System.getenv("NEXUS_ADMIN_USER") ?: System.getenv("JENKINS_ADMIN_USER") ?: "admin",
        password: System.getenv("NEXUS_ADMIN_PASSWORD") ?: System.getenv("JENKINS_ADMIN_PASSWORD") ?: "admin123",
        description: "Auto-provisioned Nexus credentials"
    ],
    [
        id: System.getenv("SONAR_CREDENTIALS_ID") ?: "sonar_admin",
        username: System.getenv("SONAR_ADMIN_USER") ?: "admin",
        password: System.getenv("SONAR_ADMIN_PASSWORD") ?: "admin123",
        description: "Auto-provisioned SonarQube credentials"
    ]
]

credentialsToEnsure.each { cfg ->
    def exists = store?.getCredentials(domain)?.any { it.id == cfg.id }
    if (!exists) {
        def creds = new UsernamePasswordCredentialsImpl(
            CredentialsScope.GLOBAL,
            cfg.id,
            cfg.description,
            cfg.username,
            cfg.password
        )
        store.addCredentials(domain, creds)
        provider.save()
        println("[pdris] Created credentials '${cfg.id}' for user '${cfg.username}'")
    } else {
        println("[pdris] Credentials '${cfg.id}' already exist")
    }
}
