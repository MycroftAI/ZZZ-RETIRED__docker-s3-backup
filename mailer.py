#!/usr/bin/env python

import sendgrid
import os
from sendgrid.helpers.mail import *

sg = sendgrid.SendGridAPIClient(apikey=os.environ.get('SENDGRID_API_KEY'))
from_email = Email("backups@mycroft.ai")
to_email = Email("dev@mycroft.ai")
subject = os.environ.get('EMAIL_SUBJECT')
content = Content("text/plain", os.environ.get('EMAIL_BODY'))
mail = Mail(from_email, subject, to_email, content)
response = sg.client.mail.send.post(request_body=mail.get())
print(response.status_code)
print(response.body)
print(response.headers)
