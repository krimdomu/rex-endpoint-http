%define perl_vendorlib %(eval "`%{__perl} -V:installvendorlib`"; echo $installvendorlib)
%define perl_vendorarch %(eval "`%{__perl} -V:installvendorarch`"; echo $installvendorarch)

%define real_name Rex-Endpoint-HTTP

Summary: HTTP Communication Daemon for Rex
Name: rex-endpoint-http
Version: 0.31.1
Release: 1
License: Apache 2.0
Group: Utilities/System
Source: http://search.cpan.org/CPAN/authors/id/J/JF/JFRIED/Rex-Endpoint-HTTP-0.31.1.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root

BuildRequires: perl-Mojolicious
BuildRequires: perl >= 5.10.1
BuildRequires: perl(ExtUtils::MakeMaker)
BuildRequires: perl(Digest::SHA)
Requires: perl-IO-Socket-SSL >= 1.75
Requires: perl >= 5.10.1
Requires: perl-Digest-SHA
Requires: perl-Mojolicious
Requires: perl-EV

%description
Rex is a tool to ease the execution of commands on multiple remote 
servers. You can define small tasks, chain tasks to batches, link 
them with servers or server groups, and execute them easily in 
your terminal. This is the HTTP Protocol Endpoint.

%prep
%setup -n %{real_name}-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS="vendor" PREFIX="%{buildroot}%{_prefix}"
%{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
%{__make} pure_install
mkdir -p %{buildroot}/etc/init.d
cp doc/rex-endpoint-http.init %{buildroot}/etc/init.d/rex-endpoint-http
chmod 0755 %{buildroot}/etc/init.d/rex-endpoint-http

### Clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;

%post

if [ ! -f "/etc/rex/user.db" ]; then
   mkdir /etc/rex
   chmod 0700 /etc/rex
   _h=$(hostname -s)
   _p=$(perl -MDigest::SHA1 -le "print Digest::SHA1::sha1_hex('${_h}')")

   echo "Creating default user database. Please change the users and/or passwords."
   echo "user: root"
   echo "password: $_h"

   echo "root:$_p" >/etc/rex/user.db

fi

if [ ! -f "/etc/rex/httpd.conf" ]; then

   echo "Creating default configuration file /etc/rex/httpd.conf"
   echo "Please create your own CA and use SSL Authentication for more security."

   cat >>/etc/rex/httpd.conf <<EOF

{
   user_file => "/etc/rex/user.db",
   hypnotoad => {
      listen => ["https://*:8443"],
   },
};

EOF


fi



%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root, 0755)
%doc META.yml 
%doc %{_mandir}/*
%{_bindir}/*
%{perl_vendorlib}/*
/etc/init.d/rex-endpoint-http

%changelog

* Mon Jul 2 2012 Jan Gehring <jan.gehring at, gmail.com> 0.31.1-1
- inital package 
