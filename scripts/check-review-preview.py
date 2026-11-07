"""Check review flows against the isolated local preview; creates/removes temporary accounts."""
import json
import time
import urllib.request
import urllib.error
import http.cookiejar
OPENER = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))

BASE = 'http://127.0.0.1:4001'
PASSWORD = 'LocalReview2026!'

def call(method, path, body=None, token=None, expected=200):
    headers = {'Content-Type': 'application/json'}
    if token: headers['Authorization'] = 'Bearer ' + token
    request = urllib.request.Request(BASE + path, data=None if body is None else json.dumps(body).encode(), headers=headers, method=method)
    try:
        with OPENER.open(request, timeout=15) as response:
            status, result = response.status, json.load(response)
    except urllib.error.HTTPError as error:
        status, result = error.code, json.load(error)
    assert status == expected, (method, path, status, result)
    return result

def main():
    call('GET', '/health')
    call('DELETE', '/api/me', {'password': PASSWORD}, expected=401)
    admin = call('POST', '/api/admin/login', {'email': 'review-admin@example.com', 'password': 'LocalReviewAdmin2026!'})
    admin_token = None  # Admin API authenticates through its HttpOnly cookie.
    stamp = str(time.time_ns())
    accounts = []
    try:
        for suffix in ['author', 'reporter']:
            username = 'check' + stamp + suffix
            account = call('POST', '/api/auth/register', {'name': 'Temporary QA ' + suffix, 'gender': 'Other', 'email': username+'@example.com', 'phone': '9999999999', 'place': 'Local QA', 'userType': 'Customer', 'username': username, 'password': PASSWORD}, expected=201)
            accounts.append((username, account['token']))
        author, reporter = accounts[0][1], accounts[1][1]
        call('DELETE', '/api/me', {'password': 'wrong-password'}, author, expected=403)
        call('GET', '/api/me', token=author)
        call('POST', '/api/testimonials', {'name': 'Anonymous', 'review': 'Anonymous submission must fail'}, expected=401)
        review = call('POST', '/api/testimonials', {'name': 'Temporary QA author', 'review': 'Temporary review for checking the report mechanism', 'rating': 4}, author, expected=201)
        review_id = review['id']
        call('PUT', '/api/admin/testimonials/'+review_id+'/status', {'status': 'approved'}, admin_token)
        public = call('GET', '/api/testimonials')['testimonials']
        assert next(item for item in public if item['id'] == review_id)['authorId']
        call('POST', '/api/testimonials/'+review_id+'/report', {'reason': 'QA report verification'}, reporter)
        assert not any(item['id'] == review_id for item in call('GET', '/api/testimonials')['testimonials'])
        overview = call('GET', '/api/admin/overview', token=admin_token)
        reported = next(item for item in overview['testimonials'] if item['id'] == review_id)
        assert reported['status'] == 'pending'
        assert reported['reports'][0]['reason'] == 'QA report verification'
        username, token = accounts.pop(0)
        call('DELETE', '/api/me', {'password': PASSWORD}, token)
        call('POST', '/api/auth/login', {'username': username, 'password': PASSWORD}, expected=401)
        call('GET', '/api/me', token=token, expected=401)
        assert not any(item['id'] == review_id for item in call('GET', '/api/admin/overview', token=admin_token)['testimonials'])
        print('PASS: authentication, wrong-password protection, authenticated reviews, reporting, moderation reasons, account deletion, session invalidation and linked review removal.')
    finally:
        for _, token in accounts:
            call('DELETE', '/api/me', {'password': PASSWORD}, token)
        call('POST', '/api/admin/logout', token=admin_token)

if __name__ == '__main__': main()
