%define perl_vendorlib %(eval "`%{__perl} -V:installvendorlib`"; echo $installvendorlib)
%define perl_vendorarch %(eval "`%{__perl} -V:installvendorarch`"; echo $installvendorarch)

%define real_name Rex

Summary: HTTP Communication Daemon for Rex
Name: rex-endpoint-http
Version: 0.0.10
Release: 1
License: Apache 2.0
Group: Utilities/System
Source: http://search.cpan.org/CPAN/authors/id/J/JF/JFRIED/Rex-Endpoint-HTTP-0.0.10.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root

BuildRequires: mojolicious
BuildRequires: perl >= 5.10.1
BuildRequires: perl(ExtUtils::MakeMaker)
BuildRequires: perl(Digest::SHA1)
Requires: perl >= 5.10.1
Requires: mojolicious

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

### Clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;


%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root, 0755)
%doc META.yml 
%doc %{_mandir}/*
%{_bindir}/*
%{perl_vendorlib}/*

%changelog

* Mon Jul 2 2012 Jan Gehring <jan.gehring at, gmail.com> 0.0.10-1
- inital package 
