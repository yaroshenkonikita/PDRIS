import hudson.security.FullControlOnceLoggedInAuthorizationStrategy
import hudson.security.HudsonPrivateSecurityRealm
import jenkins.install.InstallState
import jenkins.model.Jenkins

def instance = Jenkins.get()
def adminUser = System.getenv("JENKINS_ADMIN_USER") ?: "admin"
def adminPassword = System.getenv("JENKINS_ADMIN_PASSWORD") ?: "admin123"

HudsonPrivateSecurityRealm securityRealm
if (instance.securityRealm instanceof HudsonPrivateSecurityRealm) {
    securityRealm = instance.securityRealm as HudsonPrivateSecurityRealm
} else {
    securityRealm = new HudsonPrivateSecurityRealm(false)
}

if (securityRealm.getUser(adminUser) == null) {
    def user = securityRealm.createAccount(adminUser, adminPassword)
    user.save()
}
instance.setSecurityRealm(securityRealm)

def strategy = instance.authorizationStrategy
FullControlOnceLoggedInAuthorizationStrategy fullControlStrategy
if (strategy instanceof FullControlOnceLoggedInAuthorizationStrategy) {
    fullControlStrategy = strategy as FullControlOnceLoggedInAuthorizationStrategy
} else {
    fullControlStrategy = new FullControlOnceLoggedInAuthorizationStrategy()
}
fullControlStrategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(fullControlStrategy)

if (instance.installState != InstallState.INITIAL_SETUP_COMPLETED) {
    instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
}

instance.save()
