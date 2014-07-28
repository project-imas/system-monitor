/*
 * Original method implementations by Apple (inet.c); modified by AR on 7/24/2014
 */

/*
 * Copyright (c) 2008 Apple Inc. All rights reserved.
 *
 * @APPLE_OSREFERENCE_LICENSE_HEADER_START@
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. The rights granted to you under the License
 * may not be used to create, or enable the creation or redistribution of,
 * unlawful or unlicensed copies of an Apple operating system, or to
 * circumvent, violate, or enable the circumvention or violation of, any
 * terms of an Apple operating system software license agreement.
 *
 * Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 *
 * @APPLE_OSREFERENCE_LICENSE_HEADER_END@
 */
/*
 * Copyright (c) 1983, 1988, 1993, 1995
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#import "ConnectionInfo.h"
#import "otherConnectionHeaders.h"

@implementation ConnectionInfo

char *tcpstates[] = {
	"CLOSED",	"LISTEN",	"SYN_SENT",	"SYN_RCVD",
	"ESTABLISHED",	"CLOSE_WAIT",	"FIN_WAIT_1",	"CLOSING",
	"LAST_ACK",	"FIN_WAIT_2",	"TIME_WAIT"
};

int	aflag = 1;	/* show all sockets (including servers) */
int	bflag = 0;	/* show i/f total bytes in/out */
int	Lflag = 0;	/* show size of listen queues */
int	Wflag = 1;	/* wide display */
int	sflag = 0;	/* show protocol statistics */

NSMutableArray* getActiveConnections(uint32_t proto, char *name, int af)
{
    NSMutableArray *connections = [[NSMutableArray alloc] init];
    
	char *buf, *next;
	const char *mibvar;
	struct xinpgen *xig, *oxig;
	struct xgen_n *xgn;
	size_t len;
	struct xtcpcb_n *tp = NULL;
	struct xinpcb_n *inp = NULL;
	struct xsocket_n *so = NULL;
	struct xsockbuf_n *so_rcv = NULL;
	struct xsockbuf_n *so_snd = NULL;
	struct xsockstat_n *so_stat = NULL;
	int which = 0;
	int istcp = 0;
    
	switch (proto) {
		case IPPROTO_TCP:
#ifdef INET6
			if (tcp_done != 0)
				return;
			else
				tcp_done = 1;
#endif
			istcp = 1;
			mibvar = "net.inet.tcp.pcblist_n";
			break;
		case IPPROTO_UDP:
#ifdef INET6
			if (udp_done != 0)
				return;
			else
				udp_done = 1;
#endif
			mibvar = "net.inet.udp.pcblist_n";
			break;
		case IPPROTO_DIVERT:
			mibvar = "net.inet.divert.pcblist_n";
			break;
		default:
			mibvar = "net.inet.raw.pcblist_n";
			break;
	}

	len = 0;
	if (sysctlbyname(mibvar, 0, &len, 0, 0) < 0) {
		if (errno != ENOENT)
			warn("sysctl: %s", mibvar);
		return 0;
	}
	if ((buf = malloc(len)) == 0) {
		warn("malloc %lu bytes", (u_long)len);
		return 0;
	}
	if (sysctlbyname(mibvar, buf, &len, 0, 0) < 0) {
		warn("sysctl: %s", mibvar);
		free(buf);
		return 0;
	}
	
	/*
	 * Bail-out to avoid logic error in the loop below when
	 * there is in fact no more control block to process
	 */
	if (len <= sizeof(struct xinpgen)) {
		free(buf);
		return 0;
	}
	
	oxig = xig = (struct xinpgen *)buf;
	for (next = buf + ROUNDUP64(xig->xig_len); next < buf + len; next += ROUNDUP64(xgn->xgn_len)) {
        
        NSMutableDictionary *connection = [NSMutableDictionary dictionary];
		
		xgn = (struct xgen_n*)next;
		if (xgn->xgn_len <= sizeof(struct xinpgen))
			break;
		
		if ((which & xgn->xgn_kind) == 0) {
			which |= xgn->xgn_kind;
			switch (xgn->xgn_kind) {
				case XSO_SOCKET:
					so = (struct xsocket_n *)xgn;
					break;
				case XSO_RCVBUF:
					so_rcv = (struct xsockbuf_n *)xgn;
					break;
				case XSO_SNDBUF:
					so_snd = (struct xsockbuf_n *)xgn;
					break;
				case XSO_STATS:
					so_stat = (struct xsockstat_n *)xgn;
					break;
				case XSO_INPCB:
					inp = (struct xinpcb_n *)xgn;
					break;
				case XSO_TCPCB:
					tp = (struct xtcpcb_n *)xgn;
					break;
				default:
					printf("unexpected kind %d\n", xgn->xgn_kind);
					break;
			}
		} else {
			printf("got %d twice\n", xgn->xgn_kind);
		}
		
		if ((istcp && which != ALL_XGN_KIND_TCP) || (!istcp && which != ALL_XGN_KIND_INP))
			continue;
		which = 0;
		
		/* Ignore sockets for protocols other than the desired one. */
		if (so->xso_protocol != (int)proto)
			continue;
		
		/* Ignore PCBs which were freed during copyout. */
		if (inp->inp_gencnt > oxig->xig_gen)
			continue;
		
		if ((af == AF_INET && (inp->inp_vflag & INP_IPV4) == 0)
#ifdef INET6
		    || (af == AF_INET6 && (inp->inp_vflag & INP_IPV6) == 0)
#endif /* INET6 */
		    || (af == AF_UNSPEC && ((inp->inp_vflag & INP_IPV4) == 0
#ifdef INET6
									&& (inp->inp_vflag &
										INP_IPV6) == 0
#endif /* INET6 */
									))
		    )
			continue;
		
		/*
		 * Local address is not an indication of listening socket or
		 * server socket but just rather the socket has been bound.
		 * That why many UDP sockets were not displayed in the original code.
		 */
		if (!aflag && istcp && tp->t_state <= TCPS_LISTEN)
			continue;
		
		if (Lflag && !so->so_qlimit)
			continue;
		
		if (inp->inp_flags & INP_ANONPORT) {
			if (inp->inp_vflag & INP_IPV4) {
				//inetprint(&inp->inp_laddr, (int)inp->inp_lport, name, 1);
                //inetprint(&inp->inp_faddr, (int)inp->inp_fport, name, 0);
                [connection setObject:[NSString stringWithFormat:@"%s",inetname(&inp->inp_laddr)] forKey:@"local address"];
                setPort(connection, (int)inp->inp_lport, name, @"local port");
                [connection setObject:[NSString stringWithFormat:@"%s",inetname(&inp->inp_faddr)] forKey:@"foreign address"];
                setPort(connection, (int)inp->inp_fport, name, @"foreign port");
			}
#ifdef INET6
			else if (inp->inp_vflag & INP_IPV6) {
				inet6print(&inp->in6p_laddr,
						   (int)inp->inp_lport, name, 1);
				if (!Lflag)
					inet6print(&inp->in6p_faddr,
							   (int)inp->inp_fport, name, 0);
			} /* else nothing printed now */
#endif /* INET6 */
		} else {
			if (inp->inp_vflag & INP_IPV4) {
				//inetprint(&inp->inp_laddr, (int)inp->inp_lport,name, 0);
                //inetprint(&inp->inp_faddr,(int)inp->inp_fport, name,inp->inp_lport !=inp->inp_fport);
                
                /* local */
                [connection setObject:[NSString stringWithFormat:@"%s",inetname(&inp->inp_laddr)]
                               forKey:@"local address"];
                setPort(connection, (int)inp->inp_lport, name, @"local port");
                
                [connection setObject:[NSString stringWithFormat:@"%s",inetname(&inp->inp_faddr)] forKey:@"foreign address"];
                setPort(connection, (int)inp->inp_fport, name, @"foreign port");
			}
#ifdef INET6
			else if (inp->inp_vflag & INP_IPV6) {
				inet6print(&inp->in6p_laddr,
						   (int)inp->inp_lport, name, 0);
				if (!Lflag)
					inet6print(&inp->in6p_faddr,
							   (int)inp->inp_fport, name,
							   inp->inp_lport !=
							   inp->inp_fport);
			} /* else nothing printed now */
#endif /* INET6 */
		}
		if (istcp) {
			if (tp->t_state < 0 || tp->t_state >= TCP_NSTATES) {
                [connection setObject:[NSString stringWithFormat:@"%d",tp->t_state] forKey:@"state"];
            }
			else {
                [connection setObject:[NSString stringWithFormat:@"%s",tcpstates[tp->t_state]] forKey:@"state"];
#if defined(TF_NEEDSYN) && defined(TF_NEEDFIN)
				/* Show T/TCP `hidden state' */
				if (tp->t_flags & (TF_NEEDSYN|TF_NEEDFIN)) {
                    //[connection setObject:@"*" forKey:@"state"];
					//putchar('*');
                }
#endif /* defined(TF_NEEDSYN) && defined(TF_NEEDFIN) */
			}
		}
		
        [connections addObject:connection];
	}
	if (xig != oxig && xig->xig_gen != oxig->xig_gen) {
		if (oxig->xig_count > xig->xig_count) {
			printf("Some %s sockets may have been deleted.\n",
			       name);
		} else if (oxig->xig_count < xig->xig_count) {
			printf("Some %s sockets may have been created.\n",
			       name);
		} else {
			printf("Some %s sockets may have been created or deleted",
			       name);
		}
	}
	free(buf);
    return connections;
}

void setPort(NSMutableDictionary *connection, int port, char *name, NSString *portName) {
    struct servent *sp = 0;
    if (port) {
#ifdef _SERVICE_CACHE_
        sp = _serv_cache_getservbyport(port, name);
#else
        sp = getservbyport((int)port, name);
#endif
    }
    
    NSMutableString *result = [NSMutableString stringWithFormat:@"%hu",ntohs((u_short)port)];
    
    if (sp || port == 0) {
        if (sp)
            [result appendString:[NSString stringWithFormat:@" (%s)",sp->s_name]];
        else
            [result setString:@"*"];
    }
    
    [connection setObject:result forKey:portName];
}

/*
 * Construct an Internet address representation.
 * If the nflag has been supplied, give
 * numeric value, otherwise try for symbolic name.
 */
char *inetname(struct in_addr *inp)
{
	register char *cp;
	static char line[MAXHOSTNAMELEN];
	struct hostent *hp;
	struct netent *np;
    
	cp = 0;
	if (inp->s_addr != INADDR_ANY) {
		int net = inet_netof(*inp);
		int lna = inet_lnaof(*inp);
        
		if (lna == INADDR_ANY) {
			np = getnetbyaddr(net, AF_INET);
			if (np)
				cp = np->n_name;
		}
		if (cp == 0) {
			hp = gethostbyaddr((char *)inp, sizeof (*inp), AF_INET);
			if (hp) {
				cp = hp->h_name;
                //### trimdomain(cp, strlen(cp));
			}
		}
	}
	if (inp->s_addr == INADDR_ANY)
		strlcpy(line, "*", sizeof(line));
	else if (cp) {
		strncpy(line, cp, sizeof(line) - 1);
		line[sizeof(line) - 1] = '\0';
	} else {
		inp->s_addr = ntohl(inp->s_addr);
#define C(x)	((u_int)((x) & 0xff))
		snprintf(line, sizeof(line), "%u.%u.%u.%u", C(inp->s_addr >> 24),
                 C(inp->s_addr >> 16), C(inp->s_addr >> 8), C(inp->s_addr));
	}
	return (line);
}

- (void) printTCPConnections {
    NSArray *connections = [NSArray arrayWithArray:getActiveConnections(IPPROTO_TCP,"tcp",AF_INET)];
    NSLog(@"%@",connections);
}

- (void) printUDPConnections {
    NSArray *connections = [NSArray arrayWithArray:getActiveConnections(IPPROTO_UDP,"udp",AF_INET)];
    NSLog(@"%@",connections);
}



@end
